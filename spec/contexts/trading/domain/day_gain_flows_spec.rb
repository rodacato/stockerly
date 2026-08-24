require "rails_helper"

# The day's figure must reflect price movement only. Capital in or out is not
# a gain, whatever date the user typed on the form.
RSpec.describe Trading::Domain::PortfolioSummary, "#day_gain with external flows" do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user)).tap { |p| p.update!(buying_power: 0) }
  end

  def mxn_asset(**attrs) = create(:asset, :stock, currency: "MXN", **attrs)

  def snapshot_yesterday(total)
    portfolio.snapshots.create!(date: Date.yesterday, currency: "MXN",
                                total_value: total, cash_value: 0, invested_value: total)
  end

  def record_trade(symbol:, side: "buy", shares:, price:, on: Date.current)
    Trading::UseCases::ExecuteTrade.call(user: user, params: {
      asset_symbol: symbol, side: side, shares: shares,
      price_per_share: price, executed_at: on.to_s
    })
  end

  def day_gain = described_class.new(portfolio.reload, currency: "MXN").day_gain

  it "does not report a backdated purchase as today's gain" do
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    snapshot_yesterday(5_000)
    mxn_asset(symbol: "NEW", current_price: 10)

    record_trade(symbol: "NEW", shares: 100, price: 10, on: Date.yesterday)

    expect(day_gain.percent).to eq(0)
    expect(day_gain.absolute).to eq(0)
  end

  it "does not report a purchase made today as today's gain either" do
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    snapshot_yesterday(5_000)
    mxn_asset(symbol: "NEW", current_price: 10)

    record_trade(symbol: "NEW", shares: 100, price: 10)

    expect(day_gain.absolute).to eq(0)
  end

  it "does not report a sale as today's loss" do
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    snapshot_yesterday(5_000)

    record_trade(symbol: "HELD", side: "sell", shares: 100, price: 10)

    expect(day_gain.absolute).to eq(0)
  end

  # The whole point of the subtraction is that it removes capital, not movement.
  it "still reports a real price move in full" do
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    snapshot_yesterday(5_000)

    held.update!(current_price: 11)

    expect(day_gain.absolute).to eq(500)
    expect(day_gain.percent).to eq(10)
  end

  it "separates the move from the capital when both happen on the same day" do
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    snapshot_yesterday(5_000)
    bought = mxn_asset(symbol: "NEW", current_price: 10)

    record_trade(symbol: "NEW", shares: 100, price: 10)
    held.update!(current_price: 11)
    bought.update!(current_price: 10)

    expect(day_gain.absolute).to eq(500)
  end

  it "converts a foreign-currency flow at the rate captured on the trade" do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.current, rate: 17.0)
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    snapshot_yesterday(5_000)
    create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)

    record_trade(symbol: "AAPL", shares: 1, price: 100)

    expect(day_gain.absolute).to eq(0)
  end

  it "ignores a trade that was already in yesterday's snapshot" do
    held = mxn_asset(symbol: "HELD", current_price: 10)
    create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
    old_trade = create(:trade, portfolio: portfolio, asset: held, side: :buy, shares: 500,
                               price_per_share: 10, currency: "MXN", executed_at: 3.days.ago)
    old_trade.update_column(:created_at, 3.days.ago)
    snapshot_yesterday(5_000)

    expect(day_gain.absolute).to eq(0)
  end
end
