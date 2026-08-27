class DiscoverController < AuthenticatedController
  def show
    @calendar = MarketData::Domain::PolicyCalendar.upcoming
    @calendar_exhausted = MarketData::Domain::PolicyCalendar.exhausted?
    @calendar_horizon = MarketData::Domain::PolicyCalendar.horizon
    @calendar_sources = MarketData::Domain::PolicyCalendar.source_urls
    @alpaca_connected = Integration.exists?(provider_name: "Alpaca", connection_status: :connected)

    # The evidence D31's kill criterion needs, at the cost of a cache key: if
    # this screen goes unvisited, the decision to delete it has a number behind
    # it. Not surfaced in Ajustes yet.
    Rails.cache.write("discover:last_seen", Time.current)
  end
end
