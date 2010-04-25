require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

def billing_info(attributes={})
  attributes = {
    :first_name => 'Barry',
    :last_name => 'Gurnsberg', 
    :address1 => 'add1', 
    :city => 'Phila', 
    :state => 'PA', 
    :country => 'US', 
    :zip => '19101', 
    :phone => '215-551-1212',
    :card_number => '4242424242424242', 
    :expiration_month => 10, 
    :expiration_year => 2009, 
    :card_type => 'visa', 
    :cvn => '123'
  }.merge attributes
  Billing.new(attributes)
end

def shipping_info(attributes={})
  attributes = {
    :first_name => 'Barry',
    :last_name => 'Gurnsberg', 
    :street_address => 'add1', 
    :city => 'Phila', 
    :state => 'PA', 
    :country => 'US', 
    :zip_code => '19101', 
    :phone => '215-551-1212'
  }.merge attributes
  Customer.new(attributes)
end

def setup_test_gateway
  @gateway = ActiveMerchant::Billing::Gateway.new 'bogus'
  @auth_response = mock ActiveMerchant::Billing::Response, :null_object => true
  @cap_response = mock ActiveMerchant::Billing::Response, :null_object => true
  @gateway.stub!(:authorize).with(any_args).and_return @auth_response
  @gateway.stub!(:capture).with(any_args).and_return @cap_response
end

include MinimalCart
describe MinimalCart do
  before :each do 
    setup_test_gateway
  end
  
  it 'process_card should run without error returns success on valid info' do
    @credit_card.stub!(:valid?).and_return true
    @auth_response.stub!(:success?).and_return true
    @cap_response.stub!(:success?).and_return true
    auth_response, cap_response = process_card @credit_card, billing_info, 10000, '1.1.1.1', @gateway
    auth_response.success?.should be_true
    cap_response.success?.should be_true
  end

  it 'process_card should return authorization and capture responses' do
    @credit_card.stub!(:valid?).and_return true
    @auth_response.stub!(:success?).and_return true
    @cap_response.stub!(:success?).and_return true
    auth_response, cap_response = process_card @credit_card, billing_info, 10000, '1.1.1.1', @gateway
    auth_response.should == @auth_response
    cap_response.should == @cap_response
  end

  it 'should raise InvalidCreditCardError when card info is bad' do
    @credit_card.stub!(:valid?).and_return false
    lambda do
        process_card(@credit_card, billing_info, 10000, '1.1.1.1', @gateway)
    end.should raise_error(MinimalCart::InvalidCreditCardError) { |e|
      e.credit_card.should == @credit_card
    }
  end

  it 'should raise AuthorizationFailureError when an authorization error occurs' do
    @credit_card.stub!(:valid?).and_return true
    @auth_response.stub!(:success?).and_return false
    @cap_response.stub!(:success?).and_return true
    lambda do
      process_card @credit_card, billing_info, 10604, '1.1.1.1', @gateway
    end.should raise_error(MinimalCart::AuthorizationFailureError) { |e|
      e.responses.should include(@auth_response)
    }
  end

  it 'should raise CaptureFailureError when an authorization error occurs' do
    @credit_card.stub!(:valid?).and_return true
    @auth_response.stub!(:success?).and_return true
    @cap_response.stub!(:success?).and_return false
    lambda do
      process_card @credit_card, billing_info, 10604, '1.1.1.1', @gateway
    end.should raise_error(MinimalCart::CaptureFailureError) { |ex|
      ex.responses.should include(@auth_response)
      ex.responses.should include(@cap_response)
    }
  end
end

describe MinimalCart, 'when using it in a controller' do
  include MinimalCart::ShoppingCart
  before :each do
    setup_test_gateway
    @controller.stub!(:session).and_return({ :bill_to => billing_info, :ship_to => shipping_info })
    stub!(:get_cart).and_return Cart.new
    stub!(:total_cart).and_return 1000
    stub!(:get_gateway).and_return @gateway
    @transaction = mock_model ShoppingTransaction, :null_object => true
    @auth_yaml_return = 'the auth response'
    @cap_yaml_return = 'the cap response'
    @auth_response.stub!(:to_yaml).and_return @auth_yaml_return.to_yaml
    @cap_response.stub!(:to_yaml).and_return @cap_yaml_return.to_yaml
  end

  it 'check_out should save the transaction to the database' do
    lambda do
      check_out
    end.should change(ShoppingTransaction, :count).by(1)
  end    

  it 'check_out should save the billing info to the database' do
    lambda do
      check_out
    end.should change(Billing, :count).by(1)
  end    

  it 'charge_card should write the responses to the db on success' do
    @auth_response.stub!(:success?).and_return true
    @cap_response.stub!(:success?).and_return true
    
    lambda do
      charge_card @transaction, '1.1.1.1'
    end.should change(GatewayResponse, :count).by(2)
    auth_gwresponse = GatewayResponse.find(:first,
                                           :order => 'id DESC',
                                           :limit => 1,
                                           :offset => 1)
    auth_gwresponse.success.should be_true
    auth_gwresponse.response_object.should == @auth_yaml_return
    auth_gwresponse.shopping_transaction_id.should == @transaction.id
    cap_gwresponse = GatewayResponse.last
    cap_gwresponse.success.should be_true
    cap_gwresponse.response_object.should == @cap_yaml_return
    cap_gwresponse.shopping_transaction_id.should == @transaction.id
  end

  it 'charge_card should write the auth response to the db if there is a auth failure and reraise the exception' do
    @auth_response.stub!(:success?).and_return false
    @cap_response.stub!(:success?).and_return true
    
    lambda do
      lambda do
        charge_card @transaction, '1.1.1.1'
      end.should raise_error(MinimalCart::AuthorizationFailureError)
    end.should change(GatewayResponse, :count).by(1)
    auth_gwresponse = GatewayResponse.last
    auth_gwresponse.success.should be_false
    auth_gwresponse.response_object.should == @auth_yaml_return
    auth_gwresponse.shopping_transaction_id.should == @transaction.id
  end

  it 'charge_card should write the auth and cap responses to the db if there is a cap failure and reraise the exception' do
    @auth_response.stub!(:success?).and_return true
    @cap_response.stub!(:success?).and_return false
    
    lambda do
      lambda do
        charge_card @transaction, '1.1.1.1'
      end.should raise_error(MinimalCart::CaptureFailureError)
    end.should change(GatewayResponse, :count).by(2)
    auth_gwresponse = GatewayResponse.find(:first,
                                           :order => 'id DESC',
                                           :limit => 1,
                                           :offset => 1)
    auth_gwresponse.success.should be_true
    auth_gwresponse.response_object.should == @auth_yaml_return
    auth_gwresponse.shopping_transaction_id.should == @transaction.id
    cap_gwresponse = GatewayResponse.last
    cap_gwresponse.success.should be_false
    cap_gwresponse.response_object.should == @cap_yaml_return
    cap_gwresponse.shopping_transaction_id.should == @transaction.id
  end
end
