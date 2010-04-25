# See LICENSE file in the root for details
class ShoppingTransaction < ActiveRecord::Base
  belongs_to :shopper, :polymorphic => true
  belongs_to :shipping
  belongs_to :billing
  belongs_to :shopping_transaction_status, :foreign_key => 'status_transaction_id'
  has_many :orders, :foreign_key => 'transaction_id'
  has_many :gateway_responses
  has_many :coupon_uses
  has_many :coupons, :through => :coupon_uses

  after_create :add_transaction_code

  acts_as_ferret :fields => [ :searchable_field ]

  # transaction_code is a human readable identifier of the transaction.  It's like an order number you get after checkout, but I can't call it that because Order means something else.
  # transaction_code is based on the id, so we can't call this until after save.  This guarantees uniqueness in the table.
  def add_transaction_code
    unless transaction_code
      number = 15170000 + id
      prefix = (defined? TRANSACTION_CODE_PREFIX) ? TRANSACTION_CODE_PREFIX : ''
      self.transaction_code = "#{prefix}#{number.to_s}"
      save!
    end
  end

  def transaction_code_without_prefix
    transaction_code.match(/^#{TRANSACTION_CODE_PREFIX}(.*)$/)[1]
  end

  def searchable_field
    searchable = ''
    safe_append(searchable, transaction_code)
    
    safe_append searchable, billing.try(:email)
    safe_append searchable, billing.try(:phone)
    safe_append searchable, billing.try(:first_name)
    safe_append searchable, billing.try(:last_name)

    safe_append searchable, shipping.try(:email)
    safe_append searchable, shipping.try(:phone)
    safe_append searchable, shipping.try(:first_name)
    safe_append searchable, shipping.try(:last_name)
    
    safe_append searchable, shopper.try(:login)
    safe_append searchable, shopper.try(:email)
    safe_append searchable, shopper.try(:name)
    safe_append searchable, shopper.try(:first_name)
    safe_append searchable, shopper.try(:last_name)
  end

  private

  def safe_append(string, append, delim=' ')
    string << append unless append.nil?
    string << delim unless delim.nil?
  end
end
