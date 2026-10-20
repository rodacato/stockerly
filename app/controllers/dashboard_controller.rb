class DashboardController < AuthenticatedController
  after_action :record_open, only: :show

  def show
    data = Trading::UseCases::AssemblePanorama.call(user: current_user)

    @currency        = data[:currency]
    @summary         = data[:summary]
    @fx_unavailable  = data[:fx_unavailable]
    @prices_unavailable = data[:prices_unavailable]
    @sentiment_cards = data[:sentiment_cards]
    @signals         = data[:signals]
    @signals_window_days = data[:signals_window_days]
    @radar           = data[:radar]
    @tracks_anything = data[:tracks_anything]
    @sparkline_closes = data[:sparkline_closes]
    @day_changes     = data[:day_changes]
  end

  private

  def record_open
    return unless response.successful? && request.format.html?
    return if turbo_frame_request? || request.headers["X-Sec-Purpose"] == "prefetch"

    AppOpen.record(path: request.path)
  end
end
