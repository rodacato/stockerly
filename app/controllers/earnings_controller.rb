class EarningsController < AuthenticatedController
  def index
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    result = MarketData::ListEarnings.call(user: current_user, date: date, filter: params[:filter])

    case result
    in Dry::Monads::Success(data)
      @events           = data[:events]
      @date             = data[:date]
      @watchlist_events = data[:watchlist_events]
    end
  end

  def show
    @event = EarningsEvent.includes(:asset).find(params[:id])
  end
end
