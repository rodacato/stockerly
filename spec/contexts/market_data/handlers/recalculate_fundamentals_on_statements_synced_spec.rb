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

  it "handles Hash events (async deserialization)" do
    hash_event = { asset_id: asset.id, symbol: asset.symbol,
                   statement_types: %w[income_statement balance_sheet cash_flow] }

    expect { described_class.call(hash_event) }
      .to change { AssetFundamental.where(period_label: "CALCULATED").count }.by(1)
  end
end
