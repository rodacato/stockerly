require "rails_helper"

RSpec.describe MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced do
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 189.43) }
  let(:event) do
    MarketData::Events::FinancialStatementsSynced.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      statement_types: %w[income_statement balance_sheet cash_flow]
    )
  end

  before do
    create(:financial_statement,
      asset: asset, statement_type: :income_statement, period_type: :annual,
      fiscal_date_ending: "2023-09-30",
      data: { "total_revenue" => "383285000000", "gross_profit" => "169148000000",
              "operating_income" => "114301000000", "net_income" => "96995000000",
              "interest_expense" => "3933000000" })

    create(:financial_statement,
      asset: asset, statement_type: :balance_sheet, period_type: :annual,
      fiscal_date_ending: "2023-09-30",
      data: { "total_assets" => "352583000000", "total_current_assets" => "143566000000",
              "total_current_liabilities" => "145308000000",
              "total_shareholder_equity" => "62146000000",
              "long_term_debt" => "95281000000", "short_term_debt" => "15807000000",
              "inventory" => "6331000000" })

    create(:financial_statement,
      asset: asset, statement_type: :cash_flow, period_type: :annual,
      fiscal_date_ending: "2023-09-30",
      data: { "operating_cashflow" => "110543000000",
              "capital_expenditures" => "11000000000" })
  end

  it "creates a CALCULATED AssetFundamental" do
    expect { described_class.call(event) }
      .to change { AssetFundamental.where(asset: asset, period_label: "CALCULATED").count }.by(1)

    fundamental = AssetFundamental.find_by(asset: asset, period_label: "CALCULATED")
    expect(fundamental.source).to eq("calculated")
    expect(fundamental.metrics).to have_key("debt_to_equity")
    expect(fundamental.metrics).to have_key("net_margin")
    expect(fundamental.metrics).to have_key("free_cash_flow")
  end

  it "publishes AssetFundamentalsUpdated event" do
    handler = class_double(MarketData::Handlers::LogFundamentalsUpdate, call: nil)
    EventBus.subscribe(MarketData::Events::AssetFundamentalsUpdated, handler)

    described_class.call(event)

    expect(handler).to have_received(:call).with(an_instance_of(MarketData::Events::AssetFundamentalsUpdated))
  end

  it "skips when asset not found" do
    bad_event = MarketData::Events::FinancialStatementsSynced.new(asset_id: -1, symbol: "FAKE", statement_types: [])

    expect { described_class.call(bad_event) }
      .not_to change(AssetFundamental, :count)
  end

  it "skips when missing any statement type" do
    asset.financial_statements.cash_flows.destroy_all

    expect { described_class.call(event) }
      .not_to change(AssetFundamental, :count)
  end

  # D116: the annual statement can be a year old, and the overview beside it is TTM.
  describe "the window the ratios describe" do
    def quarter(type, date, data)
      create(:financial_statement, asset: asset, statement_type: type, period_type: :quarterly,
        fiscal_date_ending: date, data: data)
    end

    def quarters(count, income: {})
      %w[2024-06-29 2024-03-30 2023-12-30 2023-10-28].first(count).each do |date|
        quarter(:income_statement, date, { "total_revenue" => "100000000000", "net_income" => "10000000000",
          "operating_income" => "20000000000", "interest_expense" => "1000000000" }.merge(income.fetch(date, {})))
        quarter(:cash_flow, date, { "operating_cashflow" => "30000000000", "capital_expenditures" => "-3000000000" })
      end
    end

    def calculated_metrics
      described_class.call(event)
      AssetFundamental.find_by(asset: asset, period_label: "CALCULATED").metrics
    end

    it "reads the last four quarters when all four are on file" do
      quarters(4)

      metrics = calculated_metrics

      expect(metrics["net_margin"].to_d).to eq(BigDecimal("0.1"))
      expect(metrics["interest_coverage"].to_d).to eq(BigDecimal("20"))
      expect(metrics["free_cash_flow"].to_d).to eq(BigDecimal("108000000000"))
    end

    it "falls back to the annual statement when the quarters are incomplete" do
      quarters(3)

      expect(calculated_metrics["net_margin"].to_d).to eq(BigDecimal("0.2531"))
    end

    it "reads the balance ratios from the latest balance sheet, quarterly or annual" do
      quarter(:balance_sheet, "2024-06-29", { "total_current_assets" => "150000000000",
        "total_current_liabilities" => "100000000000", "total_shareholder_equity" => "70000000000" })

      expect(calculated_metrics["current_ratio"].to_d).to eq(BigDecimal("1.5"))
    end

    it "leaves a ratio out rather than divide one window by another" do
      quarters(4, income: { "2023-12-30" => { "interest_expense" => nil } })

      expect(calculated_metrics).not_to have_key("interest_coverage")
    end

    it "starts the four at the newest quarter whose statements are out, past one that carries only EPS" do
      quarters(4)
      quarter(:income_statement, "2024-09-28", { "basic_eps" => "1.2", "diluted_eps" => "1.19" })

      expect(calculated_metrics["net_margin"].to_d).to eq(BigDecimal("0.1"))
    end

    it "never skips a quarter missing in the middle, which would sum a year that was not" do
      quarters(4, income: { "2023-12-30" => { "total_revenue" => nil } })
      quarter(:income_statement, "2023-07-01", { "total_revenue" => "100000000000", "net_income" => "10000000000" })

      expect(calculated_metrics["net_margin"].to_d).to eq(BigDecimal("0.2531"))
    end
  end

  it "handles Hash events (async deserialization)" do
    hash_event = { asset_id: asset.id, symbol: asset.symbol,
                   statement_types: %w[income_statement balance_sheet cash_flow] }

    expect { described_class.call(hash_event) }
      .to change { AssetFundamental.where(period_label: "CALCULATED").count }.by(1)
  end
end
