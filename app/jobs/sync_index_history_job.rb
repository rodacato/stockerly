# Syncs daily close prices for major market indices into MarketIndexHistory.
# Uses MarketData::Gateways::YfinanceGateway#fetch_historical for OHLCV data.
# Idempotent: skips existing records via unique index on [market_index_id, date].
class SyncIndexHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  YAHOO_INDICES = %w[^GSPC ^IXIC ^DJI].freeze

  def perform(days: 5)
    gateway = MarketData::Gateways::YfinanceGateway.new
    synced = 0

    YAHOO_INDICES.each do |yahoo_sym|
      internal_sym = MarketData::Gateways::YfinanceGateway::INDEX_SYMBOL_MAP[yahoo_sym]
      index = MarketIndex.find_by(symbol: internal_sym)
      next unless index

      result = gateway.fetch_historical(yahoo_sym, days: days)
      next if result.failure?

      result.value!.each do |bar|
        next unless bar[:close]

        index.market_index_histories.find_or_create_by!(date: bar[:date], interval: "1d") do |h|
          h.close_value = bar[:close]
          h.source = MarketData::Gateways::YfinanceGateway.source_id
          h.status = "confirmed"
          h.as_of = bar[:date].end_of_day
          h.fetched_at = Time.current
        end
        synced += 1
      rescue ActiveRecord::RecordNotUnique
        next
      end
    end

    log_sync_success("Index History Sync", message: "#{synced} records synced")
  end
end
