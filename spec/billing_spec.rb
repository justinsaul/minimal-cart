require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

describe Billing do
  it 'saves the masked card number on create' do
    b = Billing.new
    b = billing_info
    b.save!
    id = b.id
    b = Billing.find id
    b.obfuscated_card_number.should_not == billing_info.card_number
    b.obfuscated_card_number.should == ActiveMerchant::Billing::CreditCard.mask(billing_info.card_number)
  end
end
