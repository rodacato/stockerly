module MoneyHelper
  # "MXN 1,247,580.40" — the shape D10 asks for whenever a figure is not in the
  # currency its list already declared. Use precision 4 for yields and FX rates.
  def format_currency_mx(amount, currency:, precision: 2)
    "#{currency} #{bare_amount_mx(amount, precision: precision)}"
  end

  # D10: a section that declares its currency once drops the prefix from every
  # row. The amount alone still comes from here, so precision and the delimiter
  # are decided in one place rather than per view.
  def bare_amount_mx(amount, precision: 2)
    number_with_precision(amount || 0, precision: precision, delimiter: ",")
  end

  # A gain or loss carries its sign, and the sign is the typographic minus for
  # the same reason signed_percent's is: a hyphen is a separator, not a sign.
  # The sign leads because the reader is scanning for direction before amount.
  def signed_currency_mx(amount, currency:, precision: 2)
    value = amount.to_d
    "#{value.negative? ? "−" : "+"}#{format_currency_mx(value.abs, currency: currency, precision: precision)}"
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
