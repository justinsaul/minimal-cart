class Coupon < ActiveRecord::Base
  has_many :coupon_uses
  has_many :shopping_transactions, :through => :coupon_uses

  validates_uniqueness_of :coupon_code
end
