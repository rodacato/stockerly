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

    # The budget is what RateLimiter actually spent, held on the integration.
    # It used to be counted from SystemLog rows, which missed two calls out of
    # every three a statements sync makes and dropped failures entirely — so
    # the quota could be gone while this job still believed it had room.
    describe "the budget it spends against" do
      let!(:integration) do
        create(:integration, provider_name: "Alpha Vantage",
                             daily_call_limit: 25, daily_api_calls: 0,
                             calls_reset_at: Time.current)
      end

      def spend(calls)
        integration.update!(daily_api_calls: calls, calls_reset_at: Time.current)
      end

      it "stops enqueueing once the calls already made leave no room for three more" do
        spend(24)

        expect { described_class.perform_now }.not_to have_enqueued_job(SyncStatementsJob)
      end

      it "counts calls that failed, because the provider charged for them anyway" do
        spend(25)

        expect { described_class.perform_now }.not_to have_enqueued_job(SyncStatementsJob)
        expect(SystemLog.where(task_name: "Statements: all", severity: :warning).count).to eq(1)
      end

      it "fits the remaining calls into whole assets" do
        spend(21)

        expect { described_class.perform_now }
          .to have_enqueued_job(SyncStatementsJob).exactly(1).times
      end

      it "reads the integration's own limit rather than a constant" do
        integration.update!(daily_call_limit: 3, daily_api_calls: 0, calls_reset_at: Time.current)

        expect { described_class.perform_now }
          .to have_enqueued_job(SyncStatementsJob).exactly(1).times
      end

      # Alpha Vantage's open-source grant would lift the cap entirely (Q-1).
      it "enqueues every eligible asset when the integration has no limit" do
        integration.update!(daily_call_limit: nil, daily_api_calls: 0, calls_reset_at: Time.current)

        expect { described_class.perform_now }
          .to have_enqueued_job(SyncStatementsJob).exactly(2).times
      end
    end
  end
end
