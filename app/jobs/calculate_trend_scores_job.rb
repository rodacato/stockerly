class CalculateTrendScoresJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    count = 0

    Asset.syncing.find_each do |asset|
      count += 1 if MarketData::UseCases::RecordTrendScore.call(asset: asset)
    end

    log_sync_success("TrendScores: #{count} assets scored")
  rescue StandardError => e
    log_sync_failure("TrendScores", e.message)
    raise
  end
end
