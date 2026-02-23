# Orchestrator: enqueues SyncFundamentalJob for each eligible asset,
# respecting the Alpha Vantage daily budget (25 calls/day free tier).
# Priority: portfolio assets > watchlist > rest.
class SyncAllFundamentalsJob < ApplicationJob
  include SyncLogging

  DAILY_BUDGET = 25
  STAGGER_SECONDS = 15

  queue_as :default

  def perform
    used_today = calls_used_today
    remaining = DAILY_BUDGET - used_today

    if remaining <= 0
      log_sync_failure("Fundamentals: all",
        "Daily budget exhausted (#{used_today}/#{DAILY_BUDGET})", severity: :warning)
      return
    end

    assets = prioritized_assets.limit(remaining)

    assets.each_with_index do |asset, index|
      SyncFundamentalJob.set(wait: index * STAGGER_SECONDS.seconds).perform_later(asset.id)
    end

    log_sync_success("Fundamentals: all",
      message: "Enqueued #{assets.size} assets (budget: #{remaining}/#{DAILY_BUDGET})")
  end

  private

  def prioritized_assets
    Asset.where(asset_type: [ :stock, :etf ], sync_status: :active)
         .where("fundamentals_synced_at IS NULL OR fundamentals_synced_at < ?", 24.hours.ago)
         .order(
           Arel.sql(<<~SQL.squish)
             CASE
               WHEN id IN (SELECT asset_id FROM positions WHERE status = 0) THEN 0
               WHEN id IN (SELECT asset_id FROM watchlist_items) THEN 1
               ELSE 2
             END ASC,
             fundamentals_synced_at ASC NULLS FIRST
           SQL
         )
  end

  def calls_used_today
    SystemLog.where("task_name LIKE ?", "Fundamentals: %")
             .where(severity: :success)
             .where(created_at: Date.current.all_day)
             .count
  end
end
