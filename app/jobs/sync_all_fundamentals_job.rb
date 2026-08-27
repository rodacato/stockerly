# Orchestrator: enqueues SyncFundamentalJob for each eligible asset,
# respecting the Alpha Vantage daily budget through FundamentalsBudget — both
# the calls already spent and the limit the integration declares.
# Priority: portfolio assets > watchlist > rest.
class SyncAllFundamentalsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  STAGGER_SECONDS = 15

  queue_as :default

  def perform
    budget = MarketData::Domain::FundamentalsBudget.today

    if budget.exhausted?
      log_sync_failure("Fundamentals: all",
        "Daily budget exhausted (#{budget.used}/#{budget.limit})", severity: :warning)
      return
    end

    assets = budget.unlimited? ? prioritized_assets : prioritized_assets.limit(budget.remaining)

    assets.each_with_index do |asset, index|
      SyncFundamentalJob.set(wait: index * STAGGER_SECONDS.seconds).perform_later(asset.id)
    end

    log_sync_success("Fundamentals: all",
      message: "Enqueued #{assets.size} assets (budget: #{budget.remaining}/#{budget.limit})")
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
end
