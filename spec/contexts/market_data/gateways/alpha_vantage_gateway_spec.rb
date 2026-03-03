require "rails_helper"

RSpec.describe MarketData::Gateways::AlphaVantageGateway do
  subject(:gateway) { described_class.new(api_key: "test_key") }

  describe "#fetch_overview" do
    context "when successful" do
      before { stub_alpha_vantage_overview("AAPL") }

      it "returns Success with parsed metrics" do
        result = gateway.fetch_overview("AAPL")
        expect(result).to be_success

        data = result.value!
        expect(data[:symbol]).to eq("AAPL")
        expect(data[:name]).to eq("AAPL Inc.")
        expect(data[:eps]).to eq(BigDecimal("6.07"))
        expect(data[:book_value]).to eq(BigDecimal("3.95"))
        expect(data[:pe_ratio]).to eq(BigDecimal("31.25"))
        expect(data[:return_on_equity]).to eq(BigDecimal("1.5700"))
        expect(data[:beta]).to eq(BigDecimal("1.24"))
        expect(data[:sector]).to eq("Technology")
      end

      it "converts numeric strings to BigDecimal" do
        result = gateway.fetch_overview("AAPL")
        data = result.value!

        expect(data[:market_cap]).to be_a(BigDecimal)
        expect(data[:revenue_ttm]).to be_a(BigDecimal)
        expect(data[:shares_outstanding]).to be_a(BigDecimal)
      end
    end

    context "when rate limited (HTTP 200 with Note key)" do
      before { stub_alpha_vantage_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_overview("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:rate_limited)
        expect(result.failure[1]).to include("Alpha Vantage")
      end
    end

    context "when auth error (HTTP 200 with Information key)" do
      before { stub_alpha_vantage_auth_error }

      it "returns Failure with :auth_error" do
        result = gateway.fetch_overview("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:auth_error)
        expect(result.failure[1]).to include("invalid")
      end
    end

    context "when symbol not found (empty response)" do
      before { stub_alpha_vantage_not_found("FAKE") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_overview("FAKE")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:not_found)
      end
    end

    context "when server error" do
      before { stub_alpha_vantage_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_overview("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:gateway_error)
      end
    end

    context "when timeout" do
      before { stub_alpha_vantage_timeout }

      it "returns Failure with :timeout" do
        result = gateway.fetch_overview("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:timeout)
      end
    end

    context "with None values from API" do
      before do
        stub_alpha_vantage_overview("AAPL", {
          "DividendPerShare" => "None",
          "DividendYield" => "0",
          "PEGRatio" => "-"
        })
      end

      it "converts None and dash to nil" do
        data = gateway.fetch_overview("AAPL").value!
        expect(data[:dividend_per_share]).to be_nil
        expect(data[:peg_ratio]).to be_nil
      end

      it "converts zero string to BigDecimal zero" do
        data = gateway.fetch_overview("AAPL").value!
        expect(data[:dividend_yield]).to eq(BigDecimal("0"))
      end
    end
  end

  describe "#fetch_income_statement" do
    context "when successful" do
      before { stub_alpha_vantage_income_statement("AAPL") }

      it "returns Success with annual and quarterly reports" do
        result = gateway.fetch_income_statement("AAPL")
        expect(result).to be_success

        data = result.value!
        expect(data[:symbol]).to eq("AAPL")
        expect(data[:annual_reports]).to be_an(Array)
        expect(data[:annual_reports].size).to eq(2)
        expect(data[:quarterly_reports].size).to eq(4)
      end

      it "normalizes keys to snake_case" do
        data = gateway.fetch_income_statement("AAPL").value!
        report = data[:annual_reports].first

        expect(report).to have_key("fiscal_date_ending")
        expect(report).to have_key("total_revenue")
        expect(report).to have_key("operating_income")
        expect(report).to have_key("net_income")
        expect(report).not_to have_key("fiscalDateEnding")
      end
    end

    context "when rate limited" do
      before { stub_alpha_vantage_rate_limited("INCOME_STATEMENT") }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_income_statement("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:rate_limited)
      end
    end

    context "when empty data" do
      before { stub_alpha_vantage_empty_statement("AAPL", "INCOME_STATEMENT") }

      it "returns Failure with :empty_data" do
        result = gateway.fetch_income_statement("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:empty_data)
      end
    end
  end

  describe "#fetch_balance_sheet" do
    context "when successful" do
      before { stub_alpha_vantage_balance_sheet("AAPL") }

      it "returns Success with annual and quarterly reports" do
        result = gateway.fetch_balance_sheet("AAPL")
        expect(result).to be_success

        data = result.value!
        expect(data[:annual_reports].size).to eq(2)
        expect(data[:quarterly_reports].size).to eq(1)
      end

      it "normalizes keys to snake_case" do
        data = gateway.fetch_balance_sheet("AAPL").value!
        report = data[:annual_reports].first

        expect(report).to have_key("total_assets")
        expect(report).to have_key("total_shareholder_equity")
        expect(report).to have_key("long_term_debt")
        expect(report).not_to have_key("totalAssets")
      end
    end

    context "when empty data" do
      before { stub_alpha_vantage_empty_statement("AAPL", "BALANCE_SHEET") }

      it "returns Failure with :empty_data" do
        result = gateway.fetch_balance_sheet("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:empty_data)
      end
    end
  end

  describe "#fetch_cash_flow" do
    context "when successful" do
      before { stub_alpha_vantage_cash_flow("AAPL") }

      it "returns Success with annual and quarterly reports" do
        result = gateway.fetch_cash_flow("AAPL")
        expect(result).to be_success

        data = result.value!
        expect(data[:annual_reports].size).to eq(2)
        expect(data[:quarterly_reports].size).to eq(4)
      end

      it "normalizes keys to snake_case" do
        data = gateway.fetch_cash_flow("AAPL").value!
        report = data[:annual_reports].first

        expect(report).to have_key("operating_cashflow")
        expect(report).to have_key("capital_expenditures")
        expect(report).to have_key("dividend_payout")
        expect(report).not_to have_key("operatingCashflow")
      end
    end

    context "when timeout" do
      before { stub_alpha_vantage_timeout("CASH_FLOW") }

      it "returns Failure with :timeout" do
        result = gateway.fetch_cash_flow("AAPL")
        expect(result).to be_failure
        expect(result.failure[0]).to eq(:timeout)
      end
    end
  end
end
