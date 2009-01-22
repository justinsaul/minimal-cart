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

  def initialize
    @errors = ActiveRecord::Errors.new(self)
    @customer = Customer.new
  end

  validates_presence_of :card_number
  validates_presence_of :cvn
  validates_presence_of :expiration_month
  validates_presence_of :expiration_year
  validates_presence_of :name
  validates_presence_of :address1
  validates_presence_of :city
  validates_presence_of :state
  validates_presence_of :zip

  def validate
    begin
      the_country = ActiveMerchant::Country.find(country)
    rescue
      errors.add_to_base("Sorry, we cannot bill to #{country}")
    end
  end
end
