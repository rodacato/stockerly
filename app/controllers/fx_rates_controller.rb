# Feeds the trade sheet's FX field: the rate for a currency ON a given date, so
# a backdated movement is priced with the fix of the day it happened (ADR-009).
class FxRatesController < AuthenticatedController
  def show
    base = params[:currency].to_s.upcase
    target = current_user.preferred_currency
    date = parsed_date

    quote = FxRateHistory.quote_on(base: base, quote: target, date: date)

    render json: {
      rate: quote&.rate&.to_f,
      base: base,
      target: target,
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
