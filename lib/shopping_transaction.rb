# See LICENSE file in the root for details
class ShoppingTransaction < ActiveRecord::Base
  belongs_to :shopper, :polymorphic => true
  belongs_to :customer
  belongs_to :shopping_transaction_status, :foreign_key => 'status_transaction_id'
  has_many :orders, :foreign_key => 'transaction_id'
  has_many :gateway_responses
end
