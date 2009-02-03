# See LICENSE file in the root for details
module MinimalCart 
  require 'yaml'
  require 'active_merchant'

  def get_gateway
    config = Config.new
    begin
      gateway = ActiveMerchant::Billing::Base.gateway(config.name.to_s).new(config.options)
    rescue
      raise 'Invalid ActiveMerchant Gateway'
    end
    gateway
  end

  def create_credit_card(billing)
    ActiveMerchant::Billing::CreditCard.new(
      :first_name => billing.first_name, 
      :last_name => billing.last_name, 
      :number => billing.card_number, 
      :month => billing.expiration_month, 
      :year => billing.expiration_year, 
      :type => billing.card_type, 
      :verification_value => billing.cvn) 
  end

  def process_card(credit_card, billing, amount_to_charge, ip_address, gateway=get_gateway)
    raise InvalidCreditCardError.new(credit_card) if !credit_card.valid?
    options = {
      :billing_address => {:name => billing.first_name + ' ' + billing.last_name, :address1 => billing.address1, :address2 => billing.address2, :city => billing.city, :state => billing.state, :country => billing.country, :zip => billing.zip, :phone => billing.phone},
      :ip => ip_address
    }
    auth_response = gateway.authorize(amount_to_charge, credit_card, options)  
    raise AuthorizationFailureError.new([auth_response]) unless auth_response.success?
    cap_response = gateway.capture(amount_to_charge, auth_response.authorization)
    raise CaptureFailureError.new([auth_response, cap_response]) unless cap_response.success?
    [ auth_response, cap_response ]
  end 

  # included is called from the Controller when you inject this module
  def self.included(base)
    base.extend ClassMethods
  end

  # declare the class level helper methods which will load the relevant instance methods defined below when invoked
  module ClassMethods
    def minimal_cart
      include MinimalCart::ShoppingCart
    end
  end

  module ShoppingCart
    def add_cart(orderable_id)
      begin
        get_cart.add orderable_id
      rescue Exception => e
        raise 'Error adding product to cart: ' + e.message
      end
    end

    def remove_cart(orderable_id)
      begin
        get_cart.remove orderable_id
      rescue Exception => e
        raise 'Error removing product: ' + e.message
      end
    end

    def update_cart(orderable_id, quantity)
      begin
        get_cart.update orderable_id, quantity
      rescue Exception => e
        raise 'Error updating the quantity of a product: ' + e.message
      end
    end

    def clear_cart
      get_cart.clear
    end

    def subtotal_cart
      return get_cart.price
    end

    def total_cart
      tax = MinimalTax::Tax.calculate get_cart, get_ship_to
      shipping = MinimalShipping::Shipping.calculate get_cart, get_ship_to
      return subtotal_cart + tax + shipping
    end

    def ship_to(shipping)
      customer = Customer.new shipping
      #raise 'Invalid Customer data in Customer object' if !customer.valid?
      begin
        customer.save!
        session[:ship_to]  = customer
      rescue Exception => exp
        raise 'Invalid Customer data in Customer object.<br>' + exp.to_s
      end
    end
    
    def bill_to(customer, billing_info)
      begin
        billing = get_billing
        billing.customer = get_ship_to
        billing.card_type = billing_info[:credit_card]
        billing.card_number = billing_info[:card_number]
        billing.expiration_month = billing_info[:expiration_month]
        billing.expiration_year = billing_info[:expiration_year]
        billing.cvn = billing_info[:card_verification_number]
        
        session[:bill_to] = billing
      rescue Exception => exp
        raise 'Invalid Customer data in Customer object.<br>' + exp.to_s
        return
      end
      
      process_card
    end
    
    private
    def get_cart
      return session[:shopping_cart] ||= Cart.new
    end

    private
    def get_billing
      return session[:bill_to] ||= Billing.new
    end

    private
    def get_ship_to
      return session[:ship_to] ||= Customer.new()
    end

    def charge_card(transaction, ip_address)
      begin
        responses = process_card create_credit_card(get_billing), get_billing, total_cart, ip_address, get_gateway
        responses.each do |r|
          response_rec = GatewayResponse.new(:success => r.success?, :response_object => r)
          response_rec.shopping_transaction = transaction
          response_rec.save!
        end
      rescue GatewayFailureError
        $!.responses.each do |r|
          response_rec = GatewayResponse.new(:success => r.success?, :response_object => r)
          response_rec.shopping_transaction = transaction
          response_rec.save!
        end
        raise $!
      end
    end

    def check_out(shopper=nil)
      #transaction
      transaction = ShoppingTransaction.new
      transaction.date = Time.now
      transaction.customer = get_billing.customer
      transaction.shopping_transaction_status = ShoppingTransactionStatus.find_by_status('NEW')
      transaction.total = total_cart
      transaction.shopper = shopper 
      transaction.save
      #orders
      get_cart.orders.values.each do |o| 
        o.shopping_transaction = transaction
        o.customer = transaction.customer
        o.save
      end
      transaction
    end
  end
  
  class Config
    attr_reader :name
    attr_reader :options
    def initialize
      config = YAML::load(File.open("#{RAILS_ROOT}/config/minimal_cart.yml"))
      raise "Please configure the ActiveMerchant Gateway" if config[RAILS_ENV] == nil
      @options = {}
      config[RAILS_ENV].each { |key, val| @options[key.to_sym] = val.to_s }
      raise 'You must specify the name option in your MinimalCart config file' unless @options[:name]
      @name = @options.delete :name
    end
  end 

  class InvalidCreditCardError < RuntimeError
    attr_reader :credit_card
    
    def initialize(credit_card)
      @credit_card = credit_card
    end
  end

  class GatewayFailureError < RuntimeError
    attr_reader :responses

    def initialize(responses)
      @responses = responses
    end
  end

  class AuthorizationFailureError < GatewayFailureError
  end

  class CaptureFailureError < GatewayFailureError
  end
end 


module MinimalTax
  class Tax
    class << self
      def calculate(cart,shipping)
        raise 'Cannot calculate tax on an empty Cart' if cart == nil
        raise 'Cannot calculate tax without valid shipping values' if shipping == nil
        tax_rate = TaxRate.find_by_country(shipping.country)
        return 0 if tax_rate == nil
        return total_tax = (cart.price * tax_rate) / 100.00 unless tax_rate == -1.0
      end
    end
  end
end


module MinimalShipping
  class Shipping
    class << self 
      def calculate(cart,shipping)
        raise 'Cannot calculate shipping on an empty Cart' if cart == nil
        raise 'Cannot calculate shipping without valid shipping values' if shipping == nil
        shipping_rate = 0.0
        #total_weight = cart.weight / 16.00 # convert from ounces to lbs
        total_weight = cart.weight
        shipping_group = CountryGroup.find_by_country(shipping.country)
        shipping_rate = ShippingRate.shipping_rate_from_weight_method_group total_weight, shipping.shipping_method, shipping_group
        return shipping_rate * 100 # pennies
      end
    end
  end
end
