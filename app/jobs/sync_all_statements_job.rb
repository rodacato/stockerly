# Orchestrator: enqueues SyncStatementsJob for eligible assets, weekly.
# 3 calls per asset (income + balance + cash flow).
#
# It does not ration against FundamentalsBudget, though since D123 it spends the
# same Yahoo quota: a weekly run is ~3 calls an asset against 4,000 a day, and
# RateLimiter still refuses each call past the ceiling. The stagger below keeps
# it inside the per-minute one.
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
