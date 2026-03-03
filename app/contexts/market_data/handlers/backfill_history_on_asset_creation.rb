module MarketData
  module Handlers
    # Enqueues a 30-day price history backfill when a new asset is created.
    # Runs async so the asset creation response is not delayed.
    class BackfillHistoryOnAssetCreation
      def self.async? = true

      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        BackfillPriceHistoryJob.perform_later(asset_id)
      end
    end
  end
end
