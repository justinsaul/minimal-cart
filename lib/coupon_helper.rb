module CouponHelper
  COUPON_TYPES = [ 
    [ 'Fixed Value (enter dollar amount)', 'FixedValueCoupon' ],
    [ 'Percent Off Total (enter percent)', 'PercentageOffCoupon' ]
  ]

  def coupon_value(coupon, subtotal)
    case coupon.class.to_s
      when 'FixedValueCoupon'
        number_to_currency coupon.value
      when 'PercentageOffCoupon'
        discount = subtotal * coupon.value / 100.to_f
        "#{coupon.value}% off #{number_to_currency(subtotal)} = #{number_to_currency(discount)}"
      else
        raise "Unknown coupon class #{coupon.class.to_s}"
    end
  end

  def type_form_column(record, input_name)
    select :record, :type, COUPON_TYPES
  end

  def type_column(record)
    record.type.underscore.titleize
  end
end
