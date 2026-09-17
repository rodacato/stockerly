require "rails_helper"

RSpec.describe SyncStatementsJob, type: :job do
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 189.43) }

  before do
    SyncStatementsJob::STATEMENT_KINDS.each { |kind| stub_yfinance_statement("AAPL", kind) }
  end

  def stub_yfinance_statement_failure(kind, tag)
    allow(PythonRunner).to receive(:call).with("yahoo.py", kind, "AAPL")
      .and_return(Dry::Monads::Failure([ tag, "no #{kind}" ]))
  end

  describe "#perform" do
    it "persists financial statements for all 3 types" do
      expect { described_class.perform_now(asset.id) }
        .to change(FinancialStatement, :count).by(12)

      expect(asset.financial_statements.income_statements.count).to eq(4)
      expect(asset.financial_statements.balance_sheets.count).to eq(4)
      expect(asset.financial_statements.cash_flows.count).to eq(4)
    end

    it "persists both annual and quarterly reports" do
      described_class.perform_now(asset.id)

      expect(asset.financial_statements.where(period_type: :annual).count).to eq(6)
      expect(asset.financial_statements.where(period_type: :quarterly).count).to eq(6)
    end

    it "publishes FinancialStatementsSynced event" do
      handler = class_double(MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced, call: nil)
      EventBus.subscribe(MarketData::Events::FinancialStatementsSynced, handler)

      described_class.perform_now(asset.id)

      expect(handler).to have_received(:call).with(an_instance_of(MarketData::Events::FinancialStatementsSynced))
    end

    it "stores correct statement data" do
      described_class.perform_now(asset.id)

      income = asset.financial_statements.income_statements.annual.recent.first
      expect(income.data).to have_key("total_revenue")
      expect(income.fiscal_year).to eq(2025)
      expect(income.source).to eq("yfinance")
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
      before { stub_yfinance_statement_failure("balance_sheet", :rate_limited) }

      it "stops fetching after rate limit and publishes partial sync" do
        handler = class_double(MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced, call: nil)
        EventBus.subscribe(MarketData::Events::FinancialStatementsSynced, handler)

        described_class.perform_now(asset.id)

        expect(asset.financial_statements.income_statements.count).to eq(4)
        expect(asset.financial_statements.balance_sheets.count).to eq(0)
        expect(PythonRunner).not_to have_received(:call).with("yahoo.py", "cash_flow", "AAPL")
        expect(handler).to have_received(:call) do |event|
          expect(event.statement_types).to eq([ "income_statement" ])
        end
      end
    end

    context "when asset not found" do
      it "returns silently" do
        expect { described_class.perform_now(-1) }
          .not_to change(FinancialStatement, :count)
      end
    end

    # Negative: there is no fallback, so a statement Yahoo cannot give is absent.
    context "when Yahoo has no balance sheet" do
      before { stub_yfinance_statement_failure("balance_sheet", :not_found) }

      it "writes no balance sheet and keeps the other two" do
        described_class.perform_now(asset.id)

        expect(asset.financial_statements.balance_sheets.count).to eq(0)
        expect(asset.financial_statements.cash_flows.count).to eq(4)
      end

      it "logs the failure once, against Yahoo" do
        described_class.perform_now(asset.id)

        expect(SystemLog.where(severity: :error).pluck(:task_name))
          .to eq([ "Statements: AAPL (BALANCE_SHEET) via yfinance" ])
      end
    end
  end
end
