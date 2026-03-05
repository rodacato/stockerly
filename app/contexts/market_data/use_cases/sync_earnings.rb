module MarketData
  module UseCases
    class SyncEarnings < ApplicationUseCase
      DEFAULT_DAYS_AHEAD = 90

      def call(days_ahead: DEFAULT_DAYS_AHEAD)
        assets = Asset.where(asset_type: :stock, sync_status: [ :active, :sync_issue ])
        cutoff_date = Date.current + days_ahead.days
        synced = 0
        chain = GatewayChain.for_capability(:earnings)

        assets.find_each do |asset|
          result = chain.fetch_earnings(asset.symbol)
          next if result.failure?

          result.value!.each do |data|
            next if data[:report_date].present? && data[:report_date] > cutoff_date

            upsert_event(asset, data)
            synced += 1
          end
        end

        publish(Events::EarningsSynced.new(count: synced))

        Success(synced)
      end

      private

      def upsert_event(asset, data)
        event = asset.earnings_events.find_or_initialize_by(report_date: data[:report_date])
        event.update!(
          timing: data[:timing] || :after_market_close,
          estimated_eps: data[:estimated_eps],
          actual_eps: data[:actual_eps]
        )
      rescue ActiveRecord::RecordInvalid
        nil
      end
    end
  end
end
