class CalculateTrendScoresJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    count = 0

    Asset.syncing.find_each do |asset|
      closes = asset.asset_price_histories.recent(30).pluck(:close).map(&:to_f)
      result = MarketData::TrendScoreCalculator.calculate(closes: closes)
      next unless result

      asset.trend_scores.create!(
        score: result[:score],
        label: result[:label],
        direction: result[:direction],
        calculated_at: Time.current
      )
      count += 1
    end

    log_sync_success("TrendScores: #{count} assets scored")
  rescue StandardError => e
    log_sync_failure("TrendScores", e.message)
    raise
  end
end
