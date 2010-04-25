class FixedValueCoupon < Coupon
  include ActionView::Helpers::NumberHelper

  def to_s
    "#{coupon_code} - #{number_to_currency(value)} Off Coupon"
  end

end
