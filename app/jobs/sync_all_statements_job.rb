# Orchestrator: enqueues SyncStatementsJob for eligible assets, weekly.
# Shares the daily Alpha Vantage budget with SyncAllFundamentalsJob, through
# FundamentalsBudget rather than a second count of its own.
# 3 API calls per asset (income + balance + cash flow).
class SyncAllStatementsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  CALLS_PER_ASSET = 3
  STAGGER_SECONDS = 15

  queue_as :default

  def perform
    budget = MarketData::Domain::FundamentalsBudget.today
    asset_slots = budget.unlimited? ? nil : budget.remaining / CALLS_PER_ASSET

    if asset_slots && asset_slots <= 0
      log_sync_failure("Statements: all",
        "Daily budget exhausted (#{budget.used}/#{budget.limit})", severity: :warning)
      return
    end

    assets = asset_slots ? eligible_assets.limit(asset_slots) : eligible_assets

    assets.each_with_index do |asset, index|
      SyncStatementsJob.set(wait: index * CALLS_PER_ASSET * STAGGER_SECONDS.seconds)
                       .perform_later(asset.id)
    end

    log_sync_success("Statements: all",
      message: "Enqueued #{assets.size} assets (budget: #{budget.remaining}/#{budget.limit})")
  end

  private

  def eligible_assets
    Asset.where(asset_type: [ :stock, :etf ], sync_status: :active)
         .where.not(fundamentals_synced_at: nil)
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
end
