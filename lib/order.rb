# See LICENSE file in the root for details
class Order < ActiveRecord::Base
  belongs_to :orderable, :polymorphic => true
  belongs_to :shopping_transaction, :foreign_key => 'transaction_id'
  validates_numericality_of :quantity, :only_integer => true

  before_save :store_price

  def calc_price
    begin
      return orderable.price * self.quantity
    rescue
      return 'Unable to calculate the weight of a Product'
    end
  end

  def price
    attributes['price'] ? attributes['price'] : calc_price
  end

  def store_price
    self.price = calc_price
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

  def self.find_product(orderable_id)
    clazz, id = orderable_id.split('.')
    clazz.constantize.find(id)
  end
end
