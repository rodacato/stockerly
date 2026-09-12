# Fetches latest market index quotes and updates MarketIndex records.
# US index levels come through the yfinance bridge: Alpaca has none and Massive
# charges for them. The IPC no longer does — DataBursatil's own index feed is
# still frozen at 2026-06-26, but NAFTRAC, the ETF that tracks the index, quotes
# live on /v2/cotizaciones, so the one MX index reads from a provider under
# contract instead of the bridge.
class SyncMarketIndicesJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  US_INDICES = %w[SPX NDX DJI UKX VIX].freeze
  MX_INDEX = "IPC".freeze

  def perform
    return close_indices unless markets_open?

    quotes = routed_quotes

    if quotes.any?
      updated = upsert_indices(quotes)
      log_sync_success("Market Indices Sync", message: "#{updated} indices updated")
      EventBus.publish(MarketData::Events::MarketIndicesUpdated.new(count: updated))
    else
      log_sync_failure("Market Indices Sync", "No index quotes from any route")
    end
  end

  private

  # Routed by market, deliberately not chained. ADR-021 tolerates
  # MarketIndex#change_percent being the provider's own field because each index
  # has exactly one provider — "no fallback to drift across". A chain would give
  # the IPC two and the figure could change measure between syncs, which is the
  # defect that ADR closed for assets. Earnings are routed the same way.
  def routed_quotes
    routes.flat_map do |gateway_class, symbols|
      result = gateway_class.new.fetch_index_quotes(symbols)
      next [] if result.failure?

      result.value!
    rescue StandardError => e
      log_sync_failure("Market Indices Sync", "#{gateway_class}: #{e.message}", severity: :warning)
      []
    end
  end

  # The IPC reads from DataBursatil through NAFTRAC when that provider is
  # configured, and from the bridge when it is not — an instance without the
  # token keeps the index it had rather than losing it. The choice is made by
  # configuration, which is stable: it cannot flip between one sync and the
  # next, so the figure's meaning does not drift (ADR-021).
  def routes
    if ApiKeyResolver.for(MarketData::Gateways::DataBursatilGateway::PROVIDER).present?
      {
        MarketData::Gateways::DataBursatilGateway => [ MX_INDEX ],
        MarketData::Gateways::YfinanceGateway => US_INDICES
      }
    else
      { MarketData::Gateways::YfinanceGateway => US_INDICES + [ MX_INDEX ] }
    end
  end

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
