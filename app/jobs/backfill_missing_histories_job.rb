# Weekly orchestrator: finds assets with insufficient price history
# and enqueues BackfillPriceHistoryJob for each.
# Runs Sunday 3am, max 50 assets, 5s stagger between jobs.
class BackfillMissingHistoriesJob < ApplicationJob
  include SyncLogging

  MAX_ASSETS = 50
  STAGGER_SECONDS = 5
  MIN_HISTORIES = 7

  queue_as :default

  def perform
    assets = assets_needing_backfill.limit(MAX_ASSETS)

    assets.each_with_index do |asset, index|
      BackfillPriceHistoryJob.set(wait: index * STAGGER_SECONDS.seconds).perform_later(asset.id)
    end

    log_sync_success("Backfill Missing Histories",
      message: "Enqueued #{assets.size} assets with < #{MIN_HISTORIES} price histories")
  end

  private

  def assets_needing_backfill
    Asset.where(sync_status: [ :active, :sync_issue ])
         .left_joins(:asset_price_histories)
         .group(:id)
         .having("COUNT(asset_price_histories.id) < ?", MIN_HISTORIES)
         .order(Arel.sql("COUNT(asset_price_histories.id) ASC"))
  end
end
