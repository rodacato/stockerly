# Fetches latest market index quotes and updates MarketIndex records.
# Index levels come through the yfinance bridge because no sanctioned provider
# serves them: Alpaca has none, Massive charges for them, and DataBursatil's
# index feed has been frozen since 2026-06-26.
class SyncMarketIndicesJob < ApplicationJob
  include PausableSync
  include SyncLogging
  include AdaptiveScheduling

  queue_as :default

  def perform
    return close_indices unless markets_open?

    chain = GatewayChain.new(
      gateways: [ MarketData::Gateways::YfinanceGateway.new ]
    )
    result = chain.fetch_index_quotes

    if result.success?
      updated = upsert_indices(result.value!)
      log_sync_success("Market Indices Sync", message: "#{updated} indices updated")
      EventBus.publish(MarketData::Events::MarketIndicesUpdated.new(count: updated))
      adaptive_reset("market_indices")
    else
      adaptive_backoff("market_indices")
      log_sync_failure("Market Indices Sync", result.failure[1])
    end
  end

  private

  def markets_open?
    MarketHours.us_market_open? || MarketHours.bmv_market_open?
  end

  # Overnight there is nothing to fetch, but the flags still have to fall:
  # skipping the run without clearing them leaves every index reading "open"
  # until the next session. This costs no provider call.
  def close_indices
    MarketIndex.where(is_open: true).update_all(is_open: false, updated_at: Time.current)
  end

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
