require "rails_helper"

# The exact scenario #183 measured. Before ADR-009, day_gain revalued
# yesterday's snapshot at TODAY's rate, so FX appreciation on the principal
# was reported as no movement at all.
RSpec.describe "Historical FX in period figures", type: :model do
  let(:user) { create(:user, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  let(:yesterday) { Date.current - 1 }

  before do
    FxRate.create!(base_currency: "USD", quote_currency: "MXN", rate: 17.5, fetched_at: Time.current)
    FxRateHistory.record(base: "USD", quote: "MXN", date: yesterday, rate: 17.0, source: "banxico_fix")
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.current, rate: 17.5, source: "banxico_fix")

    create(:portfolio_snapshot, portfolio: portfolio, date: yesterday, total_value: 3_000, currency: "USD")
  end

  it "values yesterday's snapshot at yesterday's rate" do
    value = portfolio.convert(3_000, from: "USD", to: "MXN", at_date: yesterday)

    expect(value).to eq(51_000)
  end

  it "still uses today's rate when no date is given" do
    value = portfolio.convert(3_000, from: "USD", to: "MXN")

    expect(value).to eq(52_500)
  end

  # 51,000 vs 52,500 — the 1,500 MXN of FX appreciation that used to vanish.
  it "counts the FX movement on the principal that the old code dropped" do
    honest = portfolio.convert(3_000, from: "USD", to: "MXN", at_date: yesterday)
    naive = portfolio.convert(3_000, from: "USD", to: "MXN")

    expect(naive - honest).to eq(1_500)
  end

  it "falls back to today's rate rather than raising when history is empty" do
    FxRateHistory.delete_all

    expect(portfolio.convert(3_000, from: "USD", to: "MXN", at_date: yesterday)).to eq(52_500)
  end

  it "reports day_gain against yesterday's own rate, not today's" do
    asset = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 100)
    create(:position, portfolio: portfolio, asset: asset, shares: 600, avg_cost: 80, status: :open)
    summary = Trading::Domain::PortfolioSummary.new(portfolio.reload, currency: "MXN")

    # Yesterday: USD 3,000 at 17.00 = 51,000 MXN. Today: 600 × 100 = 60,000 MXN.
    # Honest gain is 9,000; valuing yesterday at today's 17.50 would say 7,500.
    expect(summary.day_gain.absolute).to eq(9_000)
  end
end

RSpec.describe "A backdated trade", type: :model do
  let(:user) { create(:user, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 200) }

  before do
    FxRate.create!(base_currency: "USD", quote_currency: "MXN", rate: 20.0, fetched_at: Time.current)
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.0, source: "banxico_fix")
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.current, rate: 20.0, source: "banxico_fix")
    portfolio
  end

  # The residual the P0 left behind: the rate was captured at resolution time,
  # so a trade entered today for May was booked at today's rate.
  it "captures the rate of the day it was executed, not the day it was entered" do
    result = Trading::UseCases::ExecuteTrade.call(
      user: user,
      params: {
        asset_symbol: "AAPL", side: "buy", shares: 10,
        price_per_share: 150, executed_at: Date.new(2026, 5, 12).to_s
      }
    )

    expect(result).to be_success
    expect(result.value!.fx_rate_at_execution).to eq(17.0)
  end

  it "still prefers an explicit override over any lookup" do
    result = Trading::UseCases::ExecuteTrade.call(
      user: user,
      params: {
        asset_symbol: "AAPL", side: "buy", shares: 10,
        price_per_share: 150, executed_at: Date.new(2026, 5, 12).to_s,
        fx_rate_at_execution: 16.5
      }
    )

    expect(result.value!.fx_rate_at_execution).to eq(16.5)
  end
end
