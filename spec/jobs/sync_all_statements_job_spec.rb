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

    it "logs how many assets it enqueued" do
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

    # D109: the statements moved to yfinance, so this job stopped rationing
    # against Alpha Vantage's 25-a-day. It was capping a run at eight assets
    # against a budget it no longer spends, which is exactly the assets a
    # backfill needs most.
    describe "the Alpha Vantage budget it no longer spends" do
      let!(:integration) do
        create(:integration, provider_name: "Alpha Vantage",
                             daily_call_limit: 25, daily_api_calls: 0,
                             calls_reset_at: Time.current)
      end

      it "enqueues every eligible asset even with the budget fully spent" do
        integration.update!(daily_api_calls: 25, calls_reset_at: Time.current)

        expect { described_class.perform_now }
          .to have_enqueued_job(SyncStatementsJob).exactly(2).times
      end

      it "does not shrink the run when the budget is nearly gone" do
        integration.update!(daily_api_calls: 24, calls_reset_at: Time.current)

        expect { described_class.perform_now }
          .to have_enqueued_job(SyncStatementsJob).exactly(2).times
      end

      # Negative: no provider budget is read at all any more.
      it "never consults FundamentalsBudget" do
        allow(MarketData::Domain::FundamentalsBudget).to receive(:today).and_call_original

        described_class.perform_now

        expect(MarketData::Domain::FundamentalsBudget).not_to have_received(:today)
      end
    end
  end
end
