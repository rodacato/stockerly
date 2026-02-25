require "rails_helper"
require "rake"

RSpec.describe "data:backfill rake tasks" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("data:backfill_prices")
  end

  before do
    Rake::Task["data:backfill_prices"].reenable
    Rake::Task["data:backfill_earnings"].reenable
    Rake::Task["data:backfill_fundamentals"].reenable
    Rake::Task["data:backfill_all"].reenable
  end

  describe "data:backfill_prices" do
    it "enqueues BackfillPriceHistoryJob for assets with insufficient history" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active)
      # Asset has 0 price histories, should be included

      expect {
        Rake::Task["data:backfill_prices"].invoke
      }.to have_enqueued_job(BackfillPriceHistoryJob).with(asset.id)
    end

    it "skips assets with sufficient history" do
      asset = create(:asset, symbol: "MSFT", asset_type: :stock, sync_status: :active)
      7.times do |i|
        create(:asset_price_history, asset: asset, date: i.days.ago.to_date)
      end

      expect {
        Rake::Task["data:backfill_prices"].invoke
      }.not_to have_enqueued_job(BackfillPriceHistoryJob).with(asset.id)
    end
  end

  describe "data:backfill_earnings" do
    it "enqueues SyncEarningsJob" do
      expect {
        Rake::Task["data:backfill_earnings"].invoke
      }.to have_enqueued_job(SyncEarningsJob)
    end
  end

  describe "data:backfill_fundamentals" do
    it "enqueues SyncFundamentalJob for assets without fundamentals" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, fundamentals_synced_at: nil)

      expect {
        Rake::Task["data:backfill_fundamentals"].invoke
      }.to have_enqueued_job(SyncFundamentalJob).with(asset.id)
    end

    it "skips assets that already have fundamentals" do
      asset = create(:asset, symbol: "MSFT", asset_type: :stock, sync_status: :active, fundamentals_synced_at: 1.day.ago)

      expect {
        Rake::Task["data:backfill_fundamentals"].invoke
      }.not_to have_enqueued_job(SyncFundamentalJob).with(asset.id)
    end

    it "skips crypto assets" do
      asset = create(:asset, symbol: "BTC", asset_type: :crypto, sync_status: :active, fundamentals_synced_at: nil)

      expect {
        Rake::Task["data:backfill_fundamentals"].invoke
      }.not_to have_enqueued_job(SyncFundamentalJob).with(asset.id)
    end
  end
end
