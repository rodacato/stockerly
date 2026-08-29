class CalculateTrendScoresJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    count = 0

    Asset.syncing.find_each do |asset|
      histories = MarketData::Queries::PriceSeries.for(asset).latest(MarketData::Domain::TrendScoreCalculator::WINDOW)
      closes = histories.pluck(:close).map(&:to_f)
      volumes = histories.pluck(:volume).map(&:to_f)

      result = MarketData::Domain::TrendScoreCalculator.calculate(closes: closes, volumes: volumes)
      next unless result

      asset.trend_scores.create!(
        score: result[:score],
        label: result[:label],
        direction: result[:direction],
        calculated_at: Time.current,
        factors: result[:factors] || {}
      )
      count += 1
    end

    log_sync_success("TrendScores: #{count} assets scored")
  rescue StandardError => e
    log_sync_failure("TrendScores", e.message)
    raise
  end
end
