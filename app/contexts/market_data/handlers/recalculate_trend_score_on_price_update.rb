module MarketData
  module Handlers
    class RecalculateTrendScoreOnPriceUpdate
      def self.async? = true

      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id

        asset = Asset.find_by(id: asset_id)
        return unless asset

        UseCases::RecordTrendScore.call(asset: asset)
      end
    end
  end
end
