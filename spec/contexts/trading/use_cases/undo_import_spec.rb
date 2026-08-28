require "rails_helper"

RSpec.describe Trading::UseCases::UndoImport do
  let(:user) { create(:user, preferred_currency: "USD") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, symbol: "VT", currency: "USD") }

  before { FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 12, 1), rate: 18.2293, source: "banxico") }

  def import(rows)
    Trading::UseCases::ImportTrades.call(user: user, rows: rows, dry_run: false)
  end

  def row(overrides = {})
    {
      asset_symbol: "VT", side: "buy", shares: "2.0", price_per_share: "100.0",
      currency: "USD", executed_at: "2025-12-08T10:00:00-05:00", external_id: "order-1"
    }.merge(overrides)
  end

  it "removes only the trades whose external ids were given" do
    import([ row, row(external_id: "order-2") ])

    result = described_class.call(portfolio: portfolio, external_ids: [ "order-1" ])

    expect(result[:removed]).to eq(1)
    expect(portfolio.trades.pluck(:external_id)).to eq([ "order-2" ])
  end

  it "leaves the position holding only what survives" do
    import([ row, row(external_id: "order-2", shares: "3.0") ])

    described_class.call(portfolio: portfolio, external_ids: [ "order-2" ])

    expect(Position.sole.shares).to eq(2)
  end

  it "recalculates avg_cost on the surviving trades" do
    import([ row(price_per_share: "100.0"), row(external_id: "order-2", price_per_share: "300.0") ])
    expect(Position.sole.avg_cost).to eq(BigDecimal("200.0"))

    described_class.call(portfolio: portfolio, external_ids: [ "order-2" ])

    expect(Position.sole.avg_cost).to eq(BigDecimal("100.0"))
  end

  it "destroys the position when nothing is left" do
    import([ row ])

    described_class.call(portfolio: portfolio, external_ids: [ "order-1" ])

    expect(Position.count).to eq(0)
  end

  it "frees the external id so the same confirmation imports again" do
    import([ row ])
    described_class.call(portfolio: portfolio, external_ids: [ "order-1" ])

    expect(import([ row ])).to be_success
    expect(portfolio.trades.count).to eq(1)
  end

  it "does nothing when no trade carries those ids" do
    expect(described_class.call(portfolio: portfolio, external_ids: [ "never-seen" ])).to eq({ removed: 0 })
  end
end
