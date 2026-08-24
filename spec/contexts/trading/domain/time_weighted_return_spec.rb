require "rails_helper"

RSpec.describe Trading::Domain::TimeWeightedReturn do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 10) }

  def snapshot(days_ago, value)
    portfolio.snapshots.create!(date: days_ago.days.ago.to_date, currency: "MXN",
                                total_value: value, invested_value: value)
  end

  def buy(amount, days_ago:)
    create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: amount / 10.0,
                   price_per_share: 10, currency: "MXN", executed_at: days_ago.days.ago)
  end

  def sell(amount, days_ago:)
    create(:trade, portfolio: portfolio, asset: asset, side: :sell, shares: amount / 10.0,
                   price_per_share: 10, currency: "MXN", executed_at: days_ago.days.ago)
  end

  def twr(from: 10.days.ago.to_date) = described_class.new(portfolio.reload, currency: "MXN").between(from: from)

  it "reports plain growth when no money moved in or out" do
    snapshot(2, 1_000)
    snapshot(1, 1_100)

    expect(twr).to be_within(0.01).of(10.0)
  end

  # D12 in one example: the money-weighted figure says 110% because a deposit
  # landed. Nothing performed better than 10%.
  it "is not inflated by a deposit" do
    snapshot(2, 1_000)
    buy(1_000, days_ago: 1)
    snapshot(1, 2_100)

    expect(twr).to be_within(0.01).of(10.0)
  end

  it "is not depressed by a withdrawal" do
    snapshot(2, 1_000)
    sell(500, days_ago: 1)
    snapshot(1, 500)

    expect(twr).to be_within(0.01).of(0.0)
  end

  # The property that gives the method its name: sub-periods compound, so a
  # double followed by a halving is a wash rather than an average of +25%.
  it "chains sub-periods by multiplication" do
    snapshot(3, 1_000)
    snapshot(2, 2_000)
    snapshot(1, 1_000)

    expect(twr).to be_within(0.01).of(0.0)
  end

  it "treats the first deposit into an empty portfolio as no return" do
    snapshot(2, 0)
    buy(1_000, days_ago: 1)
    snapshot(1, 1_000)

    expect(twr).to eq(0.0)
  end

  it "separates the deposit from the movement on a day that has both" do
    snapshot(2, 1_000)
    buy(1_000, days_ago: 1)
    snapshot(1, 2_200)   # 1,000 held + 1,000 added + 200 earned

    expect(twr).to be_within(0.01).of(20.0)
  end

  it "reports a loss as a loss" do
    snapshot(2, 1_000)
    snapshot(1, 900)

    expect(twr).to be_within(0.01).of(-10.0)
  end

  it "returns zero when there is not enough history to compare" do
    snapshot(1, 1_000)

    expect(twr).to eq(0.0)
    expect(described_class.new(portfolio, currency: "MXN").between(from: 10.days.ago.to_date)).to eq(0.0)
  end

  it "honours the range it was given" do
    snapshot(5, 1_000)
    snapshot(4, 2_000)
    snapshot(3, 2_000)
    snapshot(2, 2_200)

    expect(twr(from: 3.days.ago.to_date)).to be_within(0.01).of(10.0)
  end

  # ADR-009: a snapshot in another currency is worth what it was worth on its
  # own date, so FX movement on the principal is part of the return.
  it "values a foreign snapshot at its own date's rate" do
    FxRateHistory.record(base: "USD", quote: "MXN", date: 2.days.ago.to_date, rate: 17.0)
    FxRateHistory.record(base: "USD", quote: "MXN", date: 1.day.ago.to_date, rate: 18.0)
    portfolio.snapshots.create!(date: 2.days.ago.to_date, currency: "USD", total_value: 100, invested_value: 100)
    portfolio.snapshots.create!(date: 1.day.ago.to_date, currency: "USD", total_value: 100, invested_value: 100)

    # 1,700 MXN to 1,800 MXN: the position did not move, the peso did.
    expect(twr).to be_within(0.01).of(5.88)
  end

  describe "against the money-weighted figure it replaces" do
    it "diverges exactly where D12 said it would" do
      snapshot(2, 1_000)
      buy(1_000, days_ago: 1)
      snapshot(1, 2_100)
      create(:position, portfolio: portfolio, asset: asset, shares: 210, avg_cost: 10, status: :open)

      money_weighted = Trading::Domain::PeriodReturnsCalculator.new(portfolio.reload, currency: "MXN")
                                                              .calculate["ALL"].percent

      expect(money_weighted).to be > 100
      expect(twr).to be_within(0.01).of(10.0)
    end
  end
end
