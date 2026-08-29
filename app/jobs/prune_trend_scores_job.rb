# Bounds a table that grows with every price sync. RecalculateTrendScoreOnPriceUpdate
# writes a row per AssetPriceUpdated, so high-priority stocks add one every 5 minutes.
class PruneTrendScoresJob < ApplicationJob
  include SyncLogging

  queue_as :default

  # Matches the window `_recent_observations` already calls recent.
  RETENTION_DAYS = 30

  def perform
    deleted = TrendScore.where(calculated_at: ...RETENTION_DAYS.days.ago)
                        .where.not(id: newest_per_asset)
                        .delete_all

    log_sync_success("Prune TrendScores", message: "Deleted #{deleted} rows older than #{RETENTION_DAYS} days")
  end

  private

  # Nothing reads history yet, but AlertEvaluator reads `latest_trend_score&.score || 0`,
  # so an asset that stopped syncing must keep its last row or its alerts silently score 0.
  def newest_per_asset
    TrendScore.select("DISTINCT ON (asset_id) id").order(:asset_id, calculated_at: :desc)
  end
end
