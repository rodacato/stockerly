# Orchestrator: enqueues SyncStatementsJob for eligible assets, weekly.
# Shares the same daily API budget (25 calls) with SyncAllFundamentalsJob.
# 3 API calls per asset (income + balance + cash flow).
class SyncAllStatementsJob < ApplicationJob
  include SyncLogging

  DAILY_BUDGET = 25
  CALLS_PER_ASSET = 3
  STAGGER_SECONDS = 15

  queue_as :default

  def perform
    used_today = calls_used_today
    remaining = DAILY_BUDGET - used_today
    asset_slots = remaining / CALLS_PER_ASSET

    if asset_slots <= 0
      log_sync_failure("Statements: all",
        "Daily budget exhausted (#{used_today}/#{DAILY_BUDGET})", severity: :warning)
      return
    end

    assets = eligible_assets.limit(asset_slots)

    assets.each_with_index do |asset, index|
      SyncStatementsJob.set(wait: index * CALLS_PER_ASSET * STAGGER_SECONDS.seconds)
                       .perform_later(asset.id)
    end

    log_sync_success("Statements: all",
      message: "Enqueued #{assets.size} assets (budget: #{remaining}/#{DAILY_BUDGET})")
  end

  private

  def eligible_assets
    Asset.where(asset_type: [ :stock, :etf ], sync_status: :active)
         .where("fundamentals_synced_at IS NOT NULL")
         .where(
           "id NOT IN (SELECT DISTINCT asset_id FROM financial_statements WHERE fetched_at > ?)",
           7.days.ago
         )
         .order(
           Arel.sql(<<~SQL.squish)
             CASE
               WHEN id IN (SELECT asset_id FROM positions WHERE status = 0) THEN 0
               WHEN id IN (SELECT asset_id FROM watchlist_items) THEN 1
               ELSE 2
             END ASC
           SQL
         )
  end

  def calls_used_today
    SystemLog.where("task_name LIKE ?", "Fundamentals: %")
             .or(SystemLog.where("task_name LIKE ?", "Statements: %"))
             .where(severity: :success)
             .where(created_at: Date.current.all_day)
             .count
  end
end
