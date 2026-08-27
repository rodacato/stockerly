# The one job Descubrir gets (D31, clause 2). It runs every 4h and writes with
# a 24h TTL, so a failed run serves stale waves rather than an empty screen.
#
# Lazy-fetching on request was the first draft and was wrong: at a weekly
# cadence every visit is a cache miss, so the reader would pay full network
# latency all 52 times a year.
#
# Zero tables, zero rows, zero events — everything lives in Rails.cache.
class WarmDiscoverJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  TASK_NAME = "Descubrir: olas".freeze
  CACHE_KEY = "discover:waves".freeze
  HEADLINES_KEY = "discover:headlines".freeze
  # Five headlines and never a feed: at a weekly cadence a news river is always
  # stale or repeated (D31, C1 Lucía).
  HEADLINES = 5
  TTL = 24.hours
  # The window is "since your last visit", capped so a long absence does not
  # make the job's cost unpredictable (S2 Adriana).
  MAX_WINDOW = 90.days
  MIN_WINDOW = 7.days

  def perform
    from = window_start
    catalogue = MarketData::Discover::BasketCatalogue

    result = MarketData::Gateways::AlpacaGateway.new.fetch_daily_bars(catalogue.symbols, from, Date.current)

    if result.failure?
      log_sync_failure(TASK_NAME, result.failure[1], severity: :warning)
      return
    end

    waves = MarketData::Discover::WaveRanking.call(bars: result.value!)
    Rails.cache.write(CACHE_KEY, { waves: waves, since: from, generated_at: Time.current }, expires_in: TTL)

    headlines = warm_headlines(catalogue)

    log_sync_success(TASK_NAME, message: "#{waves.size} baskets since #{from}, #{headlines} headlines")
  end

  private

  # Filtered to the baskets, which is what stops it being news and makes it
  # *why SMH moved*. A failure here leaves the previous headlines in place
  # rather than blanking the block — the waves above already landed.
  def warm_headlines(catalogue)
    result = MarketData::Gateways::AlpacaGateway.new
                                                .fetch_news(ticker: catalogue.symbols.join(","), limit: HEADLINES)
    return 0 if result.failure?

    headlines = result.value!.first(HEADLINES)
    Rails.cache.write(HEADLINES_KEY, { headlines: headlines, generated_at: Time.current }, expires_in: TTL)
    headlines.size
  end

  # A visitor who came yesterday still deserves a readable window, so the floor
  # is a week — below that a daily basket move is noise, not a wave.
  def window_start
    last_seen = MarketData::Discover::VisitLog.last_seen
    return MAX_WINDOW.ago.to_date if last_seen.blank?

    [ [ last_seen.to_date, MIN_WINDOW.ago.to_date ].min, MAX_WINDOW.ago.to_date ].max
  end
end
