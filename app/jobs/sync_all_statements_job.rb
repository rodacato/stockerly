# Orchestrator: enqueues SyncStatementsJob for eligible assets, weekly.
# 3 calls per asset (income + balance + cash flow).
#
# D109: it no longer rations against FundamentalsBudget. That budget is Alpha
# Vantage's 25 a day, and since the statements moved to yfinance this job does
# not spend it -- yet it was still dividing it by three and capping a run at
# eight assets. Yahoo has its own ceiling, enforced per call by RateLimiter in
# the gateway, and the stagger below keeps this job well inside it. The Alpha
# Vantage fallback can still spend the budget, which is what its own limiter is
# for; SyncAllFundamentalsJob remains the job that rations against it.
class SyncAllStatementsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  CALLS_PER_ASSET = 3
  STAGGER_SECONDS = 15

  queue_as :default

  def perform
    assets = eligible_assets

    assets.each_with_index do |asset, index|
      SyncStatementsJob.set(wait: index * CALLS_PER_ASSET * STAGGER_SECONDS.seconds)
                       .perform_later(asset.id)
    end

    log_sync_success("Statements: all", message: "Enqueued #{assets.size} assets")
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
