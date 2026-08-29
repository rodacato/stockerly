# Fetches DAYS of historical OHLCV data for a single asset and
# upserts into AssetPriceHistory. Triggered by AssetCreated event.
class BackfillPriceHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  DAYS = 365

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?

    result = fetch_history(asset)

    if result.success?
      upsert_bars(asset, result.value!, @source)
      log_sync_success("Backfill: #{asset.symbol}")
    else
      log_sync_failure("Backfill: #{asset.symbol}", result.failure[1])
    end
  end

  private

  # This used to route by asset_type alone, so a BMV asset asked Alpaca and
  # then Yahoo and never DataBursatil, which is the source that serves it.
  def fetch_history(asset)
    sources = DataSourceRegistry.for_capability(:historical, market: asset.market, asset_type: asset.asset_type)
    return Dry::Monads::Failure([ :not_supported, "Backfill not supported for #{asset.asset_type}" ]) if sources.empty?

    attempt(sources, asset)
  end

  # @source records which provider actually answered, since the fallback means
  # the winner is not knowable from the call site.
  def attempt(sources, asset)
    last = nil

    sources.each do |source|
      result = fetch_from(source.gateway_class, asset)
      next if result.nil?

      last = result
      next unless result.success?

      @source = source.gateway_class.source_id
      return result
    end

    last || Dry::Monads::Failure([ :not_configured, "No configured source for #{asset.symbol}" ])
  end

  # An unconfigured provider is skipped rather than raised, so a missing key
  # degrades to the next source instead of failing the job outright.
  def fetch_from(klass, asset)
    gateway = klass.new
    symbol = symbol_for(klass, asset)

    if accepts_days?(gateway)
      gateway.fetch_historical(symbol, days: DAYS)
    else
      gateway.fetch_historical(symbol, DAYS.days.ago.to_date, Date.current)
    end
  rescue MarketData::Gateways::ApiKeyNotConfiguredError
    nil
  end

  # The five gateways take two shapes — (symbol, from, to) and (symbol, days:)
  # — so ask the method rather than branch on the class.
  def accepts_days?(gateway)
    gateway.method(:fetch_historical).parameters.any? { |_type, name| name == :days }
  end

  # The BMV addresses an issuer differently from Yahoo, and the asset carries
  # the mapping already.
  def symbol_for(klass, asset)
    return asset.symbol unless klass.const_defined?(:PROVIDER)

    asset.symbol_for(klass::PROVIDER)
  end

  def upsert_bars(asset, bars, source)
    bars.each do |bar|
      AssetPriceHistory.find_or_initialize_by(asset_id: asset.id, date: bar[:date], interval: "1d").tap do |record|
        SourceChange.record(record, source) if record.persisted?

        record.assign_attributes(
          open: bar[:open],
          high: bar[:high],
          low: bar[:low],
          close: bar[:close],
          volume: bar[:volume],
          source: source,
          status: "confirmed",
          as_of: bar[:date].end_of_day,
          fetched_at: Time.current
        )
        record.save!
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Ignore race conditions on concurrent upserts
  end
end
