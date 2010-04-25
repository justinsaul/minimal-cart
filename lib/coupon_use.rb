class CouponUse < ActiveRecord::Base
  belongs_to :coupon
  belongs_to :shopping_transaction
end
