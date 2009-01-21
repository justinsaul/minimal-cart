# See LICENSE file in the root for details
class Order < ActiveRecord::Base
  belongs_to :orderable, :polymorphic => true
  belongs_to :customer
  belongs_to :shopping_transaction, :foreign_key => 'transaction_id'
  validates_numericality_of :quantity, :only_integer => true

  def calc_price
    begin
      debugger
      return orderable.price * self.quantity
    rescue
      return 'Unable to calculate the weight of a Product'
    end
  end

  def calc_weight
    begin
      return orderable.weight * self.quantity
    rescue
      return 'Unable to calculate the weight of a Product'
    end
  end

  #static
  def self.create_from(orderable_id)
    order = self.new
    order.orderable = find_product(orderable_id)
    order.quantity = 1
    return order
  end

  private
  
  def self.find_product(orderable_id)
    clazz, id = orderable_id.split('.')
    clazz.constantize.find(id)
  end
end
