# See LICENSE file in the root for details
class Order < ActiveRecord::Base
  belongs_to :orderable, :polymorphic => true
  belongs_to :customer
  belongs_to :shopping_transaction, :foreign_key => 'transaction_id'
  validates_numericality_of :quantity, :only_integer => true

  def calc_price
    begin
      return find_product(self.product_id).price * self.quantity
    rescue
      return 'Unable to calculate the weight of a Product'
    end
  end

  def calc_weight
    begin
      return find_product(self.product_id).weight * self.quantity
    rescue
      return 'Unable to calculate the weight of a Product'
    end
  end

  #static
  def self.create_from(product)
    order = self.new
    order.product_id = product.id
    order.quantity = 1
    return order
  end

  private
  
  def find_product(orderable_id)
    clazz, id = orderable_id.split('.')
    clazz.constantize.find(id)
  end
end
