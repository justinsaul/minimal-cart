require 'openssl'
require 'base64'

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

  before_create :store_masked_cc_number, :store_encrypted_cc_number

  def store_masked_cc_number
    self.obfuscated_card_number = ActiveMerchant::Billing::CreditCard.mask(card_number)
  end

  def store_encrypted_cc_number
    public_key_file = File.join RAILS_ROOT, 'config/public.pem'
    public_key = OpenSSL::PKey::RSA.new File.read(public_key_file)
    self.encrypted_card_number = Base64.encode64(public_key.public_encrypt("#{card_number}/#{cvn}"))
  end

  def obfuscated_card_number
    attributes['obfuscated_card_number'].blank? ? ActiveMerchant::Billing::CreditCard.mask(card_number) : attributes['obfuscated_card_number']
  end
  
  def retrieve_encrypted_cc_number(password)
    private_key_file = File.join RAILS_ROOT, 'config/private.pem'
    private_key = OpenSSL::PKey::RSA.new(File.read(private_key_file),password)
    return private_key.private_decrypt(Base64.decode64(encrypted_string))
  end
end
