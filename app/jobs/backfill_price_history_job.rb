# Fetches 30 days of historical OHLCV data for a single asset and
# upserts into AssetPriceHistory. Triggered by AssetCreated event.
class BackfillPriceHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

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

  # @source records which provider actually answered, since the fallback means
  # the winner is not knowable from the call site.
  def fetch_history(asset)
    case asset.asset_type
    when "crypto"
      @source = MarketData::Gateways::CoingeckoGateway.source_id
      MarketData::Gateways::CoingeckoGateway.new.fetch_historical(asset.symbol, days: 30)
    when "stock", "index", "etf"
      fetch_stock_history(asset.symbol)
    else
      Dry::Monads::Failure([ :not_supported, "Backfill not supported for #{asset.asset_type}" ])
    end
  end

  def fetch_stock_history(symbol)
    from_date = 30.days.ago.to_date.to_s
    to_date   = Date.current.to_s
    result = alpaca_history(symbol, from_date, to_date)

    if result&.success?
      @source = MarketData::Gateways::AlpacaGateway.source_id
      return result
    end

    @source = MarketData::Gateways::YfinanceGateway.source_id

    # Yahoo, through the bridge, covers Alpaca's failures and BMV, which it does not serve
    MarketData::Gateways::YfinanceGateway.new.fetch_historical(symbol, days: 30)
  end

  def alpaca_history(symbol, from_date, to_date)
    MarketData::Gateways::AlpacaGateway.new.fetch_historical(symbol, from_date, to_date)
  rescue MarketData::Gateways::ApiKeyNotConfiguredError
    nil
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
