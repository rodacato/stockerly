module MarketData
  module UseCases
    # One home for the trend_scores row two callers write: the nightly job for
    # every syncing asset, the price-update handler for one. Returns nil when
    # the asset has too little history for a score.
    class RecordTrendScore < SimpleUseCase
      def call(asset:)
        histories = Queries::PriceSeries.for(asset).latest(Domain::TrendScoreCalculator::WINDOW)

        result = Domain::TrendScoreCalculator.calculate(
          closes: histories.pluck(:close).map(&:to_f),
          volumes: Queries::PriceSeries.closed_volumes(histories)
        )
        return nil unless result

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
