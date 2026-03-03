require "rails_helper"

RSpec.describe MarketData::Events::FinancialStatementsSynced do
  it "creates with required attributes" do
    event = described_class.new(
      asset_id: 1,
      symbol: "AAPL",
      statement_types: %w[income_statement balance_sheet cash_flow]
    )

    expect(event.asset_id).to eq(1)
    expect(event.symbol).to eq("AAPL")
    expect(event.statement_types).to eq(%w[income_statement balance_sheet cash_flow])
    expect(event.occurred_at).to be_present
  end

  it "has an event_name" do
    event = described_class.new(asset_id: 1, symbol: "AAPL", statement_types: [])
    expect(event.event_name).to eq("market_data.events.financial_statements_synced")
  end
end
