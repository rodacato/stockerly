# Fetches latest market index quotes from Yahoo Finance and updates MarketIndex records.
class SyncMarketIndicesJob < ApplicationJob
  include SyncLogging
  include AdaptiveScheduling

  queue_as :default

  def perform
    chain = GatewayChain.new(
      gateways: [ MarketData::YahooFinanceGateway.new, MarketData::PolygonGateway.new ]
    )
    result = chain.fetch_index_quotes

    if result.success?
      updated = upsert_indices(result.value!)
      log_sync_success("Market Indices Sync", message: "#{updated} indices updated")
      EventBus.publish(MarketData::MarketIndicesUpdated.new(count: updated))
      adaptive_reset("market_indices")
    else
      adaptive_backoff("market_indices")
      log_sync_failure("Market Indices Sync", result.failure[1])
    end
  end

  private

  def upsert_indices(quotes)
    updated = 0

    quotes.each do |quote|
      index = MarketIndex.find_by(symbol: quote[:symbol])
      next unless index

      index.update!(
        value: quote[:value],
        change_percent: quote[:change_percent],
        is_open: quote[:is_open]
      )
      updated += 1
    end

    updated
  end
end
