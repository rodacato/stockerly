module MoneyHelper
  # "MXN 1,247,580.40" — the shape D10 asks for whenever a figure is not in the
  # currency its list already declared. Use precision 4 for yields and FX rates.
  def format_currency_mx(amount, currency:, precision: 2)
    "#{currency} #{number_with_precision(amount || 0, precision: precision, delimiter: ",")}"
  end

  SIGNIFICANT_DIGITS = 4
  MAX_DECIMALS = 8

  # A whole holding reads as "1,200"; a fractional one keeps four significant
  # digits rather than four decimals. The distinction is what makes it readable
  # for crypto: a fixed four decimals renders 0.000096644 BTC as "0.0001", and
  # eight everywhere renders half a share as "0.50000000".
  def format_shares(shares)
    value = shares.to_d
    precision = value.frac.zero? ? 0 : decimals_for(value)
    number_with_precision(value, precision: precision, delimiter: ",")
  end

  private

  # BigDecimal#exponent is the power of ten the value sits at, so subtracting it
  # pushes the window down to wherever the first significant digit actually is.
  def decimals_for(value)
    return SIGNIFICANT_DIGITS if value.abs >= 1

    [ SIGNIFICANT_DIGITS - value.exponent, MAX_DECIMALS ].min
  end
end
