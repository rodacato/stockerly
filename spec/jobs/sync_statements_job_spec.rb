require "rails_helper"

RSpec.describe SyncStatementsJob, type: :job do
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 189.43) }

  before do
    create(:integration, provider_name: "Alpha Vantage", api_key_encrypted: "test_key")
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
      handler = class_double(MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced, call: nil)
      EventBus.subscribe(MarketData::Events::FinancialStatementsSynced, handler)

      described_class.perform_now(asset.id)

      expect(handler).to have_received(:call).with(an_instance_of(MarketData::Events::FinancialStatementsSynced))
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
        handler = class_double(MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced, call: nil)
        EventBus.subscribe(MarketData::Events::FinancialStatementsSynced, handler)

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

  # D109: yfinance leads because Alpha Vantage's free tier refuses BALANCE_SHEET
  # as a premium endpoint. The specs above reach Alpha Vantage precisely because
  # the bridge is unavailable in test, which is the fallback working; these pin
  # the order rather than leaving it to that accident.
  describe "source priority" do
    let(:reports) do
      { symbol: "AAPL",
        annual_reports: [ { "fiscal_date_ending" => "2025-09-30", "reported_currency" => "USD",
                            "total_revenue" => "391035000000" } ],
        quarterly_reports: [] }
    end

    def yfinance_answers
      instance_double(MarketData::Gateways::YfinanceGateway).tap do |gateway|
        allow(MarketData::Gateways::YfinanceGateway).to receive(:new).and_return(gateway)
        SyncStatementsJob::STATEMENT_KINDS.each do |kind|
          allow(gateway).to receive(:"fetch_#{kind}").and_return(Dry::Monads::Success(reports))
        end
      end
    end

    it "takes the statements from yfinance when it answers" do
      yfinance_answers

      described_class.perform_now(asset.id)

      expect(asset.financial_statements.pluck(:source).uniq).to eq([ "yfinance" ])
    end

    it "never asks Alpha Vantage for a statement yfinance already gave" do
      yfinance_answers
      allow(MarketData::Gateways::AlphaVantageGateway).to receive(:new).and_call_original

      described_class.perform_now(asset.id)

      expect(MarketData::Gateways::AlphaVantageGateway).not_to have_received(:new)
    end

    it "falls back to Alpha Vantage for the statement yfinance could not give" do
      gateway = instance_double(MarketData::Gateways::YfinanceGateway)
      allow(MarketData::Gateways::YfinanceGateway).to receive(:new).and_return(gateway)
      allow(gateway).to receive(:fetch_income_statement).and_return(Dry::Monads::Success(reports))
      allow(gateway).to receive(:fetch_balance_sheet).and_return(Dry::Monads::Failure([ :not_found, "no data" ]))
      allow(gateway).to receive(:fetch_cash_flow).and_return(Dry::Monads::Failure([ :not_found, "no data" ]))

      described_class.perform_now(asset.id)

      expect(asset.financial_statements.income_statements.pluck(:source).uniq).to eq([ "yfinance" ])
      expect(asset.financial_statements.balance_sheets.pluck(:source).uniq).to eq([ "alpha_vantage" ])
    end

    # A self-hoster with no Alpha Vantage key still gets all three from Yahoo,
    # so a missing key is skipped rather than raised.
    it "skips a provider whose key is not configured" do
      Integration.where(provider_name: "Alpha Vantage").destroy_all
      yfinance_answers

      expect { described_class.perform_now(asset.id) }.not_to raise_error
      expect(asset.financial_statements.pluck(:source).uniq).to eq([ "yfinance" ])
    end

    # Negative: the statement that has no source anywhere is simply absent.
    it "writes nothing for a statement no provider could give" do
      gateway = instance_double(MarketData::Gateways::YfinanceGateway)
      allow(MarketData::Gateways::YfinanceGateway).to receive(:new).and_return(gateway)
      SyncStatementsJob::STATEMENT_KINDS.each do |kind|
        allow(gateway).to receive(:"fetch_#{kind}").and_return(Dry::Monads::Failure([ :not_found, "no data" ]))
      end
      Integration.where(provider_name: "Alpha Vantage").destroy_all

      expect { described_class.perform_now(asset.id) }.not_to change(FinancialStatement, :count)
    end
  end
end
