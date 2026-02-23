require "rails_helper"

RSpec.describe SyncAllStatementsJob, type: :job do
  let!(:stock1) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, fundamentals_synced_at: 1.day.ago) }
  let!(:stock2) { create(:asset, symbol: "MSFT", asset_type: :stock, sync_status: :active, fundamentals_synced_at: 1.day.ago) }
  let!(:crypto) { create(:asset, :crypto, symbol: "BTC", sync_status: :active, fundamentals_synced_at: 1.day.ago) }
  let!(:no_overview) { create(:asset, symbol: "NEW", asset_type: :stock, sync_status: :active, fundamentals_synced_at: nil) }
  let!(:disabled) { create(:asset, symbol: "DIS", asset_type: :stock, sync_status: :disabled, fundamentals_synced_at: 1.day.ago) }

  describe "#perform" do
    it "enqueues SyncStatementsJob for eligible stock/etf assets with OVERVIEW data" do
      expect { described_class.perform_now }
        .to have_enqueued_job(SyncStatementsJob).exactly(2).times
    end

    it "does not enqueue for crypto assets" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncStatementsJob).with(crypto.id)
    end

    it "does not enqueue for assets without OVERVIEW data" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncStatementsJob).with(no_overview.id)
    end

    it "does not enqueue for disabled assets" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncStatementsJob).with(disabled.id)
    end

    it "logs success with budget info" do
      expect { described_class.perform_now }
        .to change { SystemLog.where(task_name: "Statements: all", severity: :success).count }.by(1)
    end

    it "skips recently synced assets" do
      create(:financial_statement,
        asset: stock1, statement_type: :income_statement,
        period_type: :annual, fiscal_date_ending: "2023-09-30",
        fetched_at: 1.day.ago)

      expect { described_class.perform_now }
        .to have_enqueued_job(SyncStatementsJob).exactly(1).times
    end

    it "respects daily budget limit (3 calls per asset)" do
      # 25 budget / 3 per asset = 8 slots max; use 24 to leave 1 remaining (< 3)
      24.times do |i|
        SystemLog.create!(
          task_name: "Fundamentals: STOCK#{i}",
          module_name: "sync",
          severity: :success,
          duration_seconds: 0
        )
      end

      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncStatementsJob)
    end

    it "shares budget with SyncAllFundamentalsJob logs" do
      23.times do |i|
        SystemLog.create!(
          task_name: "Fundamentals: STOCK#{i}",
          module_name: "sync",
          severity: :success,
          duration_seconds: 0
        )
      end

      # Only 2 remaining calls, not enough for 3 per asset
      expect { described_class.perform_now }
        .not_to have_enqueued_job(SyncStatementsJob)
    end
  end
end
