require "rails_helper"

RSpec.describe RetryFailedAssetsJob, type: :job do
  before do
    create(:integration, provider_name: "Polygon.io", pool_key_value: "test_key")
    create(:integration, provider_name: "CoinGecko", pool_key_value: "test_key")
    SyncSingleAssetJob::CIRCUIT_BREAKERS.each_value(&:reset!)
  end

  describe "#perform" do
    context "with no assets in sync_issue" do
      it "does nothing" do
        expect {
          described_class.perform_now
        }.not_to change(SystemLog, :count)
      end
    end

    context "with a recoverable stock asset" do
      let!(:asset) do
        create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :sync_issue,
               sync_issue_since: 1.day.ago, current_price: 180.00)
      end

      before { stub_polygon_price("AAPL", close: 189.43) }

      it "recovers the asset to active status" do
        described_class.perform_now

        asset.reload
        expect(asset.sync_status).to eq("active")
        expect(asset.sync_issue_since).to be_nil
      end

      it "updates the asset price" do
        described_class.perform_now

        asset.reload
        expect(asset.current_price.to_f).to eq(189.43)
        expect(asset.price_updated_at).to be_present
      end

      it "logs a success recovery entry" do
        expect {
          described_class.perform_now
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to include("Retry Recovered")
        expect(log.task_name).to include("AAPL")
      end
    end

    context "when gateway fails during retry" do
      let!(:asset) do
        create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :sync_issue,
               sync_issue_since: 2.days.ago)
      end

      before do
        stub_polygon_server_error
        stub_yahoo_finance_server_error
      end

      it "keeps asset in sync_issue status" do
        described_class.perform_now

        asset.reload
        expect(asset.sync_status).to eq("sync_issue")
      end

      it "logs a warning entry" do
        expect {
          described_class.perform_now
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("warning")
        expect(log.task_name).to include("Retry Failed")
      end
    end

    context "with an asset in sync_issue for 7+ days" do
      let!(:asset) do
        create(:asset, symbol: "OLD", asset_type: :stock, sync_status: :sync_issue,
               sync_issue_since: 8.days.ago)
      end

      it "auto-disables the asset" do
        described_class.perform_now

        asset.reload
        expect(asset.sync_status).to eq("disabled")
      end

      it "logs a warning about auto-disable" do
        expect {
          described_class.perform_now
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("warning")
        expect(log.task_name).to include("Auto-disabled")
        expect(log.task_name).to include("OLD")
      end
    end

    context "with a crypto asset in sync_issue" do
      let!(:asset) do
        create(:asset, symbol: "BTC", asset_type: :crypto, sync_status: :sync_issue,
               sync_issue_since: 1.day.ago)
      end

      before { stub_coingecko_prices }

      it "recovers using CoinGecko gateway" do
        described_class.perform_now

        asset.reload
        expect(asset.sync_status).to eq("active")
        expect(asset.sync_issue_since).to be_nil
      end
    end

    context "respects MAX_RETRIES_PER_RUN limit" do
      before do
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/.+/prev})
          .with(query: hash_including("apiKey"))
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { results: [ { "c" => 100.0, "o" => 99.0, "h" => 101.0, "l" => 98.0, "v" => 1000 } ], resultsCount: 1 }.to_json
          )
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
          .to_return(status: 500, body: "Error")
        12.times do |i|
          create(:asset, symbol: "TST#{i}", asset_type: :stock, sync_status: :sync_issue,
                 sync_issue_since: 1.day.ago)
        end
      end

      it "processes at most 10 assets per run" do
        described_class.perform_now

        still_issue = Asset.where(sync_status: :sync_issue).count
        expect(still_issue).to be >= 2
      end
    end
  end
end
