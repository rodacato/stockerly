require "rails_helper"

RSpec.describe SyncAllFundamentalsJob, type: :job do
  let!(:stock1) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active) }
  let!(:stock2) { create(:asset, symbol: "MSFT", asset_type: :stock, sync_status: :active) }
  let!(:etf) { create(:asset, symbol: "SPY", asset_type: :etf, sync_status: :active) }
  let!(:crypto) { create(:asset, :crypto, symbol: "BTC", sync_status: :active) }
  let!(:disabled) { create(:asset, symbol: "DIS", asset_type: :stock, sync_status: :disabled) }

  describe "#perform" do
    it "enqueues SyncFundamentalJob for eligible stocks and ETFs" do
      expect { described_class.perform_now }
        .to have_enqueued_job(SyncFundamentalJob).exactly(3).times
    end

    it "does not enqueue for crypto assets" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncFundamentalJob).with(crypto.id)
    end

    it "does not enqueue for disabled assets" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncFundamentalJob).with(disabled.id)
    end

    it "logs success with budget info" do
      expect { described_class.perform_now }
        .to change { SystemLog.where(task_name: "Fundamentals: all", severity: :success).count }.by(1)
    end

    it "skips recently synced assets" do
      stock1.update!(fundamentals_synced_at: 1.hour.ago)

      expect { described_class.perform_now }
        .to have_enqueued_job(SyncFundamentalJob).exactly(2).times

      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncFundamentalJob).with(stock1.id)
    end

    it "respects daily budget limit" do
      25.times do |i|
        SystemLog.create!(
          task_name: "Fundamentals: STOCK#{i}",
          module_name: "sync",
          severity: :success,
          duration_seconds: 0
        )
      end

      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncFundamentalJob)
    end

    context "prioritization" do
      let(:user) { create(:user) }

      before do
        create(:portfolio, user: user)
        create(:position, portfolio: user.portfolio, asset: stock2, status: :open)
        create(:watchlist_item, user: user, asset: etf)
      end

      it "prioritizes portfolio assets over watchlist over rest" do
        # We can verify the query ordering indirectly
        assets = described_class.new.send(:prioritized_assets).to_a
        asset_ids = assets.map(&:id)

        stock2_idx = asset_ids.index(stock2.id)
        etf_idx = asset_ids.index(etf.id)
        stock1_idx = asset_ids.index(stock1.id)

        expect(stock2_idx).to be < etf_idx
        expect(etf_idx).to be < stock1_idx
      end
    end
  end
end
