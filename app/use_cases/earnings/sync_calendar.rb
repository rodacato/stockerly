module Earnings
  class SyncCalendar < ApplicationUseCase
    def call
      assets = Asset.syncing.where(asset_type: :stock)
      synced = 0

      assets.find_each do |asset|
        result = PolygonGateway.new.fetch_earnings(asset.symbol)
        next if result.failure?

        result.value!.each do |data|
          upsert_event(asset, data)
          synced += 1
        end
      end

      publish(EarningsSynced.new(count: synced))

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
