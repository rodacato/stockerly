module MarketData
  module Handlers
    class RecalculateTrendScoreOnPriceUpdate
      def self.async? = true

      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id

        asset = Asset.find_by(id: asset_id)
        return unless asset

        histories = asset.asset_price_histories.recent(50)
        closes = histories.pluck(:close).map(&:to_f)
        volumes = histories.pluck(:volume).map(&:to_f)

        result = Domain::TrendScoreCalculator.calculate(closes: closes, volumes: volumes)
        return unless result

        asset.trend_scores.create!(
          score: result[:score],
          label: result[:label],
          direction: result[:direction],
          calculated_at: Time.current,
          factors: result[:factors] || {}
        )
      end
    end
  end
end
