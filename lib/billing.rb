class Billing < ActiveRecord::Base
  attr_accessor :comments
  attr_accessor :card_number
  attr_accessor :cvn

  validates_presence_of :card_number, :message => 'You must enter a Credit Card Number'
  validates_presence_of :cvn, :message => 'You must enter your Credit Card Security Code'
  validates_presence_of :card_type, :message => 'You must enter your Credit Card type'
  validates_presence_of :expiration_month, :message => 'You must enter your Credit Card expiration month'
  validates_presence_of :expiration_year, :message => 'You must enter your Credit Card expiration year'
  validates_presence_of :first_name, :message => 'You must enter a billing first name'
  validates_presence_of :last_name, :message => 'You must enter a billing last name'
  validates_presence_of :address1, :message => 'You must enter a billing address'
  validates_presence_of :city, :message => 'You must enter a billing city'
  validates_presence_of :state, :message => 'You must enter a billing state or province'
  validates_presence_of :zip, :message => 'You must enter a billing ZIP or Postal code'
  validates_presence_of :phone, :message => 'You must enter a billing phone number.'

  before_create :store_masked_cc_number

  def store_masked_cc_number
    self.obfuscated_card_number = ActiveMerchant::Billing::CreditCard.mask(card_number)
  end

  def obfuscated_card_number
    attributes['obfuscated_card_number'].blank? ? ActiveMerchant::Billing::CreditCard.mask(card_number) : attributes['obfuscated_card_number']
  end
end
