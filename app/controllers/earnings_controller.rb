class EarningsController < AuthenticatedController
  def index
    data = MarketData::UseCases::ListEarnings.call(
      user:           current_user,
      periodo:        params[:periodo].presence || MarketData::UseCases::ListEarnings::DEFAULT_PERIOD,
      mercado:        params[:mercado].presence || "todos",
      watchlist_only: ActiveModel::Type::Boolean.new.cast(params[:watchlist_only])
    )

    @periodo        = data[:periodo]
    @mercado        = data[:mercado]
    @watchlist_only = data[:watchlist_only]
    @upcoming       = data[:upcoming]
    @recent         = data[:recent]
    @counts         = data[:counts]
  end

  def show
    @event = EarningsEvent.includes(:asset).find(params[:id])
  end
end
