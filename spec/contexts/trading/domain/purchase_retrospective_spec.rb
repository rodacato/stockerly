require "rails_helper"

RSpec.describe Trading::Domain::PurchaseRetrospective do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 184) }
  let(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 40, avg_cost: 120, status: :open) }

  def buy(shares, price, days_ago:)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy,
                   shares: shares, price_per_share: price, currency: "USD",
                   executed_at: days_ago.days.ago)
  end

  # A falling then recovering series, so RSI is computable and not degenerate.
  def seed_closes(days: 60)
    days.downto(0) do |i|
      create(:asset_price_history, asset: asset, date: i.days.ago.to_date,
                                   close: 150 - ((i % 12) * 4))
    end
  end

  it "reports how many buys, at what weighted average price" do
    seed_closes
    buy(25, 110, days_ago: 40)
    buy(15, 137, days_ago: 20)

    summary = described_class.call(position.reload)

    expect(summary.count).to eq(2)
    expect(summary.average_price).to be_within(0.01).of(((25 * 110) + (15 * 137)) / 40.0)
    expect(summary.currency).to eq("USD")
  end

  it "reports the RSI those days read" do
    seed_closes
    buy(10, 110, days_ago: 30)

    expect(described_class.call(position.reload).average_rsi).to be_between(1, 100)
  end

  # The gap the design cannot see: a purchase older than the asset's own price
  # history has no RSI to recover, and the block should be absent rather than
  # averaged from whatever exists.
  it "is nil when no buy date has enough history behind it" do
    create(:asset_price_history, asset: asset, date: Date.current, close: 184)
    buy(10, 110, days_ago: 300)

    expect(described_class.call(position.reload)).to be_nil
  end

  it "is nil with no history at all" do
    buy(10, 110, days_ago: 30)

    expect(described_class.call(position.reload)).to be_nil
  end

  it "is nil for a position with no buys" do
    seed_closes

    expect(described_class.call(position.reload)).to be_nil
  end

  it "ignores sells and discarded trades" do
    seed_closes
    buy(20, 110, days_ago: 40)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :sell,
                   shares: 5, price_per_share: 180, currency: "USD", executed_at: 10.days.ago)
    buy(10, 200, days_ago: 30).discard!

    summary = described_class.call(position.reload)

    expect(summary.count).to eq(1)
    expect(summary.average_price).to be_within(0.01).of(110)
  end
end
