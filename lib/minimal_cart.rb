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
  
  def process_paypal_express(amount, ip_address, express_token, payer_id)
    PAYPAL_EXPRESS_GATEWAY.purchase(amount, {
      :ip => ip_address,
      :token => express_token,
      :payer_id => payer_id
    }) 
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
        get_cart.add orderable_id
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
      total = subtotal_cart + calculate_tax + (calculate_shipping || 0) - calculate_coupon_discount
      total < 0 ? 0 : total
    end

    def ship_to(shipping_info)
      shipping = Shipping.new shipping_info
      begin
        shipping.save!
        session[:ship_to] = shipping
      rescue Exception => exp
        raise 'Invalid Shipping data in Shipping object.<br>' + exp.to_s
      end
    end

    def calculate_tax
       MinimalTax::Tax.calculate get_cart, get_ship_to
    end

    def calculate_shipping
      MinimalShipping::Shipping.calculate get_cart, get_ship_to.country, get_ship_to.shipping_type_id
    end

    def calculate_coupon_discount
      unless session[:coupons]
        return 0
      end

      total_discount = 0
      session[:coupons].each do |c|
        case c.class.to_s
        when 'FixedValueCoupon'
          total_discount += c.value
        when 'PercentageOffCoupon'
          total_discount += (subtotal_cart*(c.value/100.0))
        else
          raise "Unknown coupon class #{c.class.to_s} for #{c.pretty_inspect}"
        end
      end
      total_discount
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
      return session[:ship_to] ||= Shipping.new
    end

    def setup_paypal_express(ip_address, return_url, cancel_url)
      response = PAYPAL_EXPRESS_GATEWAY.setup_purchase(total_cart*100, 
                  :ip => ip_address, 
                  :return_url => return_url,
                  :cancel_return_url => cancel_url)
      redirect_to PAYPAL_EXPRESS_GATEWAY.redirect_url_for(response.token) and return
    end
    
    def charge_card(transaction, ip_address)
      begin
        responses = process_card create_credit_card(get_billing), get_billing, total_cart*100, ip_address, get_gateway
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
    
    def charge_paypal_express(transaction, ip_address, express_token, payer_id = nil)
      begin
        responses = process_paypal_express total_cart*100, ip_address, express_token, payer_id
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
      transaction.shipping = session[:ship_to]
      transaction.billing = session[:bill_to]
      transaction.shopping_transaction_status = ShoppingTransactionStatus.find_by_status('NEW')
      transaction.subtotal = subtotal_cart
      transaction.total = total_cart
      transaction.tax_cost = calculate_tax
      transaction.shipping_cost = calculate_shipping || 0
      transaction.shopper = shopper 
      if session[:coupons]
        transaction.coupons += session[:coupons]
        transaction.coupon_discount = calculate_coupon_discount
      end
      transaction.save
      #orders
      get_cart.orders.values.each do |o| 
        o.shopping_transaction = transaction
        o.save
      end
      transaction
    end

    def close_out_coupons
      if session[:coupons]
        session[:coupons].each do |c| 
          c.times_used ||= 0
          c.times_used += 1
          c.enabled = false if c.expire_after_use 
          c.save
        end
      end
    end

    def add_coupon(coupon_code)
      coupon_code = coupon_code.upcase
      coupon = Coupon.find_by_coupon_code coupon_code
      unless coupon
        raise InvalidCouponError.new "#{coupon_code} is not a valid coupon code."
      end
      unless coupon.enabled
        raise InvalidCouponError.new "The coupon #{coupon_code} is no longer valid."
      end

      # Can't combine percentage off coupons
      if coupon.class.to_s == 'PercentageOffCoupon' && session[:coupons]
        percentage_off_coupons = session[:coupons].select { |c| c.class.to_s == 'PercentageOffCoupon' }
        unless percentage_off_coupons.nil? || percentage_off_coupons.empty?
          raise InvalidCouponError.new "Sorry, you can't combine coupons that take a percentage off of your total. If you want to use coupon #{coupon_code}, you need to remove #{percentage_off_coupons.first.coupon_code.upcase} first."
        end
      end

      session[:coupons] ||= []
      session[:coupons] << coupon unless session[:coupons].include? coupon
    end

    def remove_coupon(coupon_code)
      session[:coupons].reject! { |c| c.coupon_code == coupon_code }
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

  class InvalidCouponError < RuntimeError
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
        tax_rate = TaxRate.find_by_country_and_state(shipping.country, shipping.state)
        return 0 if tax_rate == nil
        return total_tax = (cart.price * tax_rate.rate) / 100.00 unless tax_rate == -1.0
      end
    end
  end
end
