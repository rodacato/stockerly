require "rails_helper"

RSpec.describe FundamentalCalculator do
  let(:income_data) do
    {
      "total_revenue" => "383285000000",
      "gross_profit" => "169148000000",
      "operating_income" => "114301000000",
      "net_income" => "96995000000",
      "ebitda" => "125820000000",
      "interest_expense" => "3933000000"
    }
  end

  let(:balance_data) do
    {
      "total_assets" => "352583000000",
      "total_current_assets" => "143566000000",
      "total_current_liabilities" => "145308000000",
      "total_shareholder_equity" => "62146000000",
      "long_term_debt" => "95281000000",
      "short_term_debt" => "15807000000",
      "inventory" => "6331000000"
    }
  end

  let(:cash_flow_data) do
    {
      "operating_cashflow" => "110543000000",
      "capital_expenditures" => "11000000000",
      "dividend_payout" => "15025000000"
    }
  end

  let(:overview_metrics) do
    { "market_cap" => "2940000000000" }
  end

  describe ".calculate" do
    subject(:result) do
      described_class.calculate(
        income_data: income_data,
        balance_data: balance_data,
        cash_flow_data: cash_flow_data,
        overview_metrics: overview_metrics
      )
    end

    it "returns a hash with all calculated metrics" do
      expect(result).to be_a(Hash)
      expect(result.keys).to include(
        :debt_to_equity, :current_ratio, :quick_ratio,
        :net_margin, :operating_margin, :gross_margin,
        :interest_coverage, :free_cash_flow, :fcf_yield,
        :roe_calculated, :roa_calculated
      )
    end

    it "excludes nil values from the result" do
      expect(result.values).not_to include(nil)
    end
  end

  describe "health metrics" do
    describe "debt_to_equity" do
      it "calculates (short_term_debt + long_term_debt) / equity" do
        result = described_class.calculate(
          income_data: {}, balance_data: balance_data,
          cash_flow_data: {}, overview_metrics: {}
        )
        # (15807 + 95281) / 62146 = 1.7878 (approx)
        expect(result[:debt_to_equity]).to be_a(BigDecimal)
        expect(result[:debt_to_equity]).to be > 1
        expect(result[:debt_to_equity]).to be < 2
      end

      it "returns nil when equity is zero" do
        balance = balance_data.merge("total_shareholder_equity" => "0")
        result = described_class.calculate(
          income_data: {}, balance_data: balance,
          cash_flow_data: {}, overview_metrics: {}
        )
        expect(result).not_to have_key(:debt_to_equity)
      end

      it "defaults missing debt fields to zero" do
        balance = balance_data.except("short_term_debt")
        result = described_class.calculate(
          income_data: {}, balance_data: balance,
          cash_flow_data: {}, overview_metrics: {}
        )
        expect(result[:debt_to_equity]).to be_present
      end
    end

    describe "current_ratio" do
      it "calculates current_assets / current_liabilities" do
        result = described_class.calculate(
          income_data: {}, balance_data: balance_data,
          cash_flow_data: {}, overview_metrics: {}
        )
        # 143566 / 145308 ≈ 0.988
        expect(result[:current_ratio]).to be_a(BigDecimal)
        expect(result[:current_ratio]).to be > 0.9
        expect(result[:current_ratio]).to be < 1.1
      end

      it "returns nil when liabilities is zero" do
        balance = balance_data.merge("total_current_liabilities" => "0")
        result = described_class.calculate(
          income_data: {}, balance_data: balance,
          cash_flow_data: {}, overview_metrics: {}
        )
        expect(result).not_to have_key(:current_ratio)
      end
    end

    describe "quick_ratio" do
      it "calculates (current_assets - inventory) / current_liabilities" do
        result = described_class.calculate(
          income_data: {}, balance_data: balance_data,
          cash_flow_data: {}, overview_metrics: {}
        )
        # (143566 - 6331) / 145308 ≈ 0.944
        expect(result[:quick_ratio]).to be < result[:current_ratio]
      end

      it "falls back when inventory is missing" do
        balance = balance_data.except("inventory")
        result = described_class.calculate(
          income_data: {}, balance_data: balance,
          cash_flow_data: {}, overview_metrics: {}
        )
        # Without inventory, quick_ratio equals current_ratio
        expect(result[:quick_ratio]).to eq(result[:current_ratio])
      end
    end
  end

  describe "profitability metrics" do
    describe "net_margin" do
      it "calculates net_income / total_revenue" do
        result = described_class.calculate(
          income_data: income_data, balance_data: {},
          cash_flow_data: {}, overview_metrics: {}
        )
        # 96995 / 383285 ≈ 0.2530
        expect(result[:net_margin]).to be_a(BigDecimal)
        expect(result[:net_margin]).to be > 0.2
        expect(result[:net_margin]).to be < 0.3
      end

      it "returns nil when revenue is zero" do
        income = income_data.merge("total_revenue" => "0")
        result = described_class.calculate(
          income_data: income, balance_data: {},
          cash_flow_data: {}, overview_metrics: {}
        )
        expect(result).not_to have_key(:net_margin)
      end
    end

    describe "interest_coverage" do
      it "calculates operating_income / interest_expense" do
        result = described_class.calculate(
          income_data: income_data, balance_data: {},
          cash_flow_data: {}, overview_metrics: {}
        )
        # 114301 / 3933 ≈ 29.06
        expect(result[:interest_coverage]).to be > 20
      end

      it "returns nil when interest_expense is zero" do
        income = income_data.merge("interest_expense" => "0")
        result = described_class.calculate(
          income_data: income, balance_data: {},
          cash_flow_data: {}, overview_metrics: {}
        )
        expect(result).not_to have_key(:interest_coverage)
      end

      it "returns nil when interest_expense is nil" do
        income = income_data.except("interest_expense")
        result = described_class.calculate(
          income_data: income, balance_data: {},
          cash_flow_data: {}, overview_metrics: {}
        )
        expect(result).not_to have_key(:interest_coverage)
      end
    end
  end

  describe "cash flow metrics" do
    describe "free_cash_flow" do
      it "calculates operating_cashflow - abs(capex)" do
        result = described_class.calculate(
          income_data: {}, balance_data: {},
          cash_flow_data: cash_flow_data, overview_metrics: {}
        )
        # 110543B - 11B = 99543B
        expect(result[:free_cash_flow]).to eq(
          BigDecimal("110543000000") - BigDecimal("11000000000")
        )
      end

      it "handles negative capex values" do
        cf = cash_flow_data.merge("capital_expenditures" => "-11000000000")
        result = described_class.calculate(
          income_data: {}, balance_data: {},
          cash_flow_data: cf, overview_metrics: {}
        )
        expect(result[:free_cash_flow]).to eq(
          BigDecimal("110543000000") - BigDecimal("11000000000")
        )
      end
    end

    describe "fcf_yield" do
      it "calculates fcf / market_cap" do
        result = described_class.calculate(
          income_data: {}, balance_data: {},
          cash_flow_data: cash_flow_data, overview_metrics: overview_metrics
        )
        expect(result[:fcf_yield]).to be_a(BigDecimal)
        expect(result[:fcf_yield]).to be > 0
        expect(result[:fcf_yield]).to be < 0.1
      end

      it "returns nil when market_cap is zero" do
        result = described_class.calculate(
          income_data: {}, balance_data: {},
          cash_flow_data: cash_flow_data,
          overview_metrics: { "market_cap" => "0" }
        )
        expect(result).not_to have_key(:fcf_yield)
      end

      it "accepts symbol keys for overview_metrics" do
        result = described_class.calculate(
          income_data: {}, balance_data: {},
          cash_flow_data: cash_flow_data,
          overview_metrics: { market_cap: "2940000000000" }
        )
        expect(result[:fcf_yield]).to be_present
      end
    end
  end

  describe "return metrics" do
    it "calculates roe_calculated as net_income / equity" do
      result = described_class.calculate(
        income_data: income_data, balance_data: balance_data,
        cash_flow_data: {}, overview_metrics: {}
      )
      # 96995 / 62146 ≈ 1.5607
      expect(result[:roe_calculated]).to be > 1
      expect(result[:roe_calculated]).to be < 2
    end

    it "calculates roa_calculated as net_income / total_assets" do
      result = described_class.calculate(
        income_data: income_data, balance_data: balance_data,
        cash_flow_data: {}, overview_metrics: {}
      )
      # 96995 / 352583 ≈ 0.2751
      expect(result[:roa_calculated]).to be > 0.2
      expect(result[:roa_calculated]).to be < 0.3
    end
  end

  describe ".calculate_ttm" do
    let(:quarterly_reports) do
      [
        { "total_revenue" => "89498000000", "net_income" => "22956000000", "operating_cashflow" => "26000000000" },
        { "total_revenue" => "81797000000", "net_income" => "19881000000", "operating_cashflow" => "26400000000" },
        { "total_revenue" => "94836000000", "net_income" => "24160000000", "operating_cashflow" => "34000000000" },
        { "total_revenue" => "117154000000", "net_income" => "29998000000", "operating_cashflow" => "34143000000" }
      ]
    end

    it "sums last 4 quarters for numeric fields" do
      result = described_class.calculate_ttm(quarterly_reports)

      expected_revenue = BigDecimal("89498000000") + BigDecimal("81797000000") +
                         BigDecimal("94836000000") + BigDecimal("117154000000")
      expect(result["total_revenue"]).to eq(expected_revenue)
    end

    it "returns empty hash when fewer than 4 quarters" do
      expect(described_class.calculate_ttm(quarterly_reports.first(3))).to eq({})
    end

    it "returns empty hash for nil input" do
      expect(described_class.calculate_ttm(nil)).to eq({})
    end

    it "skips fields where any quarter has nil value" do
      reports = quarterly_reports.dup
      reports[2] = reports[2].except("net_income")
      result = described_class.calculate_ttm(reports)

      expect(result).to have_key("total_revenue")
      expect(result).not_to have_key("net_income")
    end
  end

  describe ".cagr" do
    it "calculates compound annual growth rate" do
      # 200 → 800 in 5 years: (800/200)^(1/5) - 1 ≈ 0.3195
      result = described_class.cagr(800, 200, 5)
      expect(result).to be_within(0.001).of(0.3195)
    end

    it "returns nil for negative start value" do
      expect(described_class.cagr(100, -50, 3)).to be_nil
    end

    it "returns nil for zero start value" do
      expect(described_class.cagr(100, 0, 3)).to be_nil
    end

    it "returns nil for zero years" do
      expect(described_class.cagr(100, 50, 0)).to be_nil
    end

    it "returns nil for negative end value" do
      expect(described_class.cagr(-100, 50, 3)).to be_nil
    end

    it "returns nil when all inputs are nil" do
      expect(described_class.cagr(nil, nil, nil)).to be_nil
    end
  end

  describe "edge cases" do
    it "handles None string values" do
      income = { "net_income" => "None", "total_revenue" => "383285000000" }
      result = described_class.calculate(
        income_data: income, balance_data: {},
        cash_flow_data: {}, overview_metrics: {}
      )
      expect(result).not_to have_key(:net_margin)
    end

    it "handles dash string values" do
      income = { "net_income" => "-", "total_revenue" => "383285000000" }
      result = described_class.calculate(
        income_data: income, balance_data: {},
        cash_flow_data: {}, overview_metrics: {}
      )
      expect(result).not_to have_key(:net_margin)
    end

    it "handles empty hashes" do
      result = described_class.calculate(
        income_data: {}, balance_data: {},
        cash_flow_data: {}, overview_metrics: {}
      )
      expect(result).to eq({})
    end
  end
end
