module MarketData
  module UseCases
    # Syncs upcoming earnings for stock assets. Routes by exchange:
    # BMV emisoras hit Yahoo Finance directly (the only source covering MX
    # earnings); everything else goes through the GatewayChain for the
    # :earnings capability (Finnhub primary, Polygon fallback).
    #
    # Routing is explicit rather than chained because Finnhub returns
    # Success([]) for unknown tickers (instead of a Failure), so the chain
    # would short-circuit at Finnhub and never reach Yahoo for `.MX`.
    class SyncEarnings < ApplicationUseCase
      DEFAULT_DAYS_AHEAD = 90

      def call(days_ahead: DEFAULT_DAYS_AHEAD)
        cutoff_date = Date.current + days_ahead.days
        synced = sync_us(cutoff_date) + sync_bmv(cutoff_date)

        publish(Events::EarningsSynced.new(count: synced))

        Success(synced)
      end

      private

      def sync_us(cutoff_date)
        chain  = GatewayChain.for_capability(:earnings)
        assets = Asset.where(asset_type: :stock, sync_status: [ :active, :sync_issue ])
                      .where.not(exchange: "BMV")
        sync_with(assets, cutoff_date) { |symbol| chain.fetch_earnings(symbol) }
      end

      def sync_bmv(cutoff_date)
        gateway = MarketData::Gateways::YahooFinanceGateway.new
        assets  = Asset.where(asset_type: :stock, sync_status: [ :active, :sync_issue ], exchange: "BMV")
        sync_with(assets, cutoff_date) { |symbol| gateway.fetch_earnings(symbol) }
      end

      def sync_with(assets, cutoff_date)
        synced = 0

        assets.find_each do |asset|
          result = yield(asset.symbol)
          next if result.failure?

          result.value!.each do |data|
            next if data[:report_date].present? && data[:report_date] > cutoff_date

            upsert_event(asset, data)
            synced += 1
          end
        end

        synced
      end

      def upsert_event(asset, data)
        event = asset.earnings_events.find_or_initialize_by(report_date: data[:report_date])
        event.update!(
          timing: data[:timing] || :after_market_close,
          estimated_eps: data[:estimated_eps],
          actual_eps: data[:actual_eps],
          confirmed: data.fetch(:confirmed, true)
        )
      rescue ActiveRecord::RecordInvalid
        nil
      end
    end
  end
end
