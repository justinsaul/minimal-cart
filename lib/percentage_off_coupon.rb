class PercentageOffCoupon < Coupon
  def to_s
    "#{coupon_code} - #{value}% Off Coupon"  
  end
end
