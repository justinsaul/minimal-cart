# See LICENSE file in the root for details
require 'active_record/validations'
class Billing
  # using AR Validations, but no database table
  attr_accessor :errors
  def save;end
  def save!;end
  def new_record?;false;end
  def update_attribute;end
  include ActiveRecord::Validations
  # end for AR Validations

  attr_accessor :comments
  attr_accessor :card_type
  attr_accessor :card_number
  attr_accessor :cvn
  attr_accessor :expiration_month
  attr_accessor :expiration_year
  attr_accessor :name
  attr_accessor :address1
  attr_accessor :address2
  attr_accessor :city
  attr_accessor :state
  attr_accessor :zip
  attr_accessor :country
  attr_accessor :customer
  attr_accessor :phone

  def initialize(attributes=nil)
    @errors = ActiveRecord::Errors.new(self)
    @customer = Customer.new

    if attributes
      attributes.each do |key, val|
        instance_variable_set(:"@#{key}", val)
      end
    end
  end

  validates_presence_of :card_number, :message => 'You must enter a Credit Card Number'
  validates_presence_of :cvn, :message => 'You must enter your Credit Card Security Code'
  validates_presence_of :expiration_month, :message => 'You must enter your Credit Card expiration month'
  validates_presence_of :expiration_year, :message => 'You must enter your Credit Card expiration year'
  validates_presence_of :name, :message => 'You must enter a billing name'
  validates_presence_of :address1, :message => 'You must enter a billing address'
  validates_presence_of :city, :message => 'You must enter a billing city'
  validates_presence_of :state, :message => 'You must enter a billing state or province'
  validates_presence_of :zip, :message => 'You must enter a billing ZIP or Postal code'
  validates_presence_of :phone, :message => 'You must enter a billing phone number.'
end
