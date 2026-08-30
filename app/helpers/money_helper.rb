module MoneyHelper
  # "MXN 1,247,580.40" — the shape D10 asks for whenever a figure is not in the
  # currency its list already declared. Use precision 4 for yields and FX rates.
  def format_currency_mx(amount, currency:, precision: 2)
    "#{currency} #{number_with_precision(amount || 0, precision: precision, delimiter: ",")}"
  end

  # A whole holding reads as "1,200"; a fractional one keeps the four decimals
  # a crypto position needs, rather than rounding it to nothing.
  def format_shares(shares)
    value = shares.to_d
    number_with_precision(value, precision: value.frac.zero? ? 0 : 4, delimiter: ",")
  end
end
