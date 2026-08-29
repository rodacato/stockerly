# Feeds the trade sheet's FX field: the rate for a currency ON a given date, so
# a backdated movement is priced with the fix of the day it happened (ADR-009).
class FxRatesController < AuthenticatedController
  # `rate` is what gets stored on the trade: its currency against the reference,
  # never against the preference. `display_divisor` is the second half the sheet
  # needs to show a running total in the currency the user reads in.
  def show
    base = params[:currency].to_s.upcase
    reference = Trading::Domain::ExecutionRate::REFERENCE
    date = parsed_date

    quote = FxRateHistory.quote_on(base: base, quote: reference, date: date)
    divisor = FxRateHistory.rate_on(base: current_user.preferred_currency, quote: reference, date: date)

    render json: {
      rate: quote&.rate&.to_f,
      base: base,
      target: reference,
      display_currency: current_user.preferred_currency,
      display_divisor: divisor&.to_f,
      date: (quote&.rate_date || date).to_s,
      source: quote&.source
    }
  end

  private

  def parsed_date
    Date.parse(params[:date].to_s)
  rescue Date::Error, TypeError
    Date.current
  end
end
