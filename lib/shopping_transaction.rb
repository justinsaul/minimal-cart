# See LICENSE file in the root for details
class ShoppingTransaction < ActiveRecord::Base
  belongs_to :shopper, :polymorphic => true
  belongs_to :customer
  belongs_to :shopping_transaction_status, :foreign_key => 'status_transaction_id'
  has_many :orders, :foreign_key => 'transaction_id'
  has_many :gateway_responses

  after_create :add_transaction_code

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
end
