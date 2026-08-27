class DiscoverController < AuthenticatedController
  def show
    @calendar = MarketData::Discover::PolicyCalendar.upcoming
    @calendar_exhausted = MarketData::Discover::PolicyCalendar.exhausted?
    @calendar_horizon = MarketData::Discover::PolicyCalendar.horizon
    @calendar_sources = MarketData::Discover::PolicyCalendar.source_urls
    cached = Rails.cache.read(WarmDiscoverJob::CACHE_KEY)
    @waves = cached&.dig(:waves) || []
    @waves_since = cached&.dig(:since)
    @waves_generated_at = cached&.dig(:generated_at)

    # The chip is crossed here rather than inside MarketData::Discover: ADR-002
    # pairs Trading as MarketData's customer, not the reverse, so the world does
    # not read the instance — the screen does, through Trading's own door.
    @owned_symbols = Trading::UseCases::OwnedSymbols.call(user: current_user)

    # What decides the empty state is whether there is world data to show, not
    # whether a credential exists: a connected Alpaca whose job has not run yet
    # still has nothing to say, and should say so.
    @has_world_data = @waves.any?

    # The evidence D31's kill criterion needs, surfaced on Ajustes › Estado.
    MarketData::Discover::VisitLog.record
  end
end
