require "rails_helper"

RSpec.describe SyncStatementsJob, type: :job do
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 189.43) }

  before do
    stub_alpha_vantage_income_statement("AAPL")
    stub_alpha_vantage_balance_sheet("AAPL")
    stub_alpha_vantage_cash_flow("AAPL")
  end

  describe "#perform" do
    it "persists financial statements for all 3 types" do
      expect { described_class.perform_now(asset.id) }
        .to change(FinancialStatement, :count).by_at_least(6)

      expect(asset.financial_statements.income_statements.count).to be >= 2
      expect(asset.financial_statements.balance_sheets.count).to be >= 2
      expect(asset.financial_statements.cash_flows.count).to be >= 2
    end

    it "persists both annual and quarterly reports" do
      described_class.perform_now(asset.id)

      expect(asset.financial_statements.where(period_type: :annual).count).to be >= 3
      expect(asset.financial_statements.where(period_type: :quarterly).count).to be >= 3
    end

    it "publishes FinancialStatementsSynced event" do
      handler = class_double(RecalculateFundamentalsOnStatementsSynced, call: nil)
      EventBus.subscribe(FinancialStatementsSynced, handler)

      described_class.perform_now(asset.id)

      expect(handler).to have_received(:call).with(an_instance_of(FinancialStatementsSynced))
    end

    it "stores correct statement data" do
      described_class.perform_now(asset.id)

      income = asset.financial_statements.income_statements.annual.recent.first
      expect(income.data).to have_key("total_revenue")
      expect(income.fiscal_year).to eq(2023)
      expect(income.source).to eq("alpha_vantage")
    end

    it "upserts on subsequent calls (no duplicates)" do
      described_class.perform_now(asset.id)
      initial_count = FinancialStatement.count

      described_class.perform_now(asset.id)
      expect(FinancialStatement.count).to eq(initial_count)
    end

    context "when asset is disabled" do
      let(:asset) { create(:asset, symbol: "AAPL", sync_status: :disabled) }

      it "skips without API call" do
        expect { described_class.perform_now(asset.id) }
          .not_to change(FinancialStatement, :count)
      end
    end

    context "when asset is crypto" do
      let(:asset) { create(:asset, :crypto, symbol: "BTC", sync_status: :active) }

      it "skips crypto assets" do
        expect { described_class.perform_now(asset.id) }
          .not_to change(FinancialStatement, :count)
      end
    end

    context "when rate limited mid-stream" do
      before do
        WebMock.reset!
        stub_alpha_vantage_income_statement("AAPL")
        stub_alpha_vantage_rate_limited("BALANCE_SHEET")
      end

      it "stops fetching after rate limit and publishes partial sync" do
        handler = class_double(RecalculateFundamentalsOnStatementsSynced, call: nil)
        EventBus.subscribe(FinancialStatementsSynced, handler)

        described_class.perform_now(asset.id)

        expect(asset.financial_statements.income_statements.count).to be >= 1
        expect(asset.financial_statements.balance_sheets.count).to eq(0)
        expect(handler).to have_received(:call) do |event|
          types = event.is_a?(Hash) ? event[:statement_types] : event.statement_types
          expect(types).to include("income_statement")
          expect(types).not_to include("balance_sheet")
        end
      end
    end

    context "when asset not found" do
      it "returns silently" do
        expect { described_class.perform_now(-1) }
          .not_to change(FinancialStatement, :count)
      end
    end
  end
end
