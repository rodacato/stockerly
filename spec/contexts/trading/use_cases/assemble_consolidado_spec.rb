require "rails_helper"

RSpec.describe Trading::UseCases::AssembleConsolidado do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user)).tap { |p| p.update!(inception_date: 2.years.ago.to_date) }
  end
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 12) }

  def snapshot(days_ago, value)
    portfolio.snapshots.create!(date: days_ago.days.ago.to_date, currency: "MXN",
                                total_value: value)
  end

  def buy(shares, price, days_ago:)
    create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: shares,
                   price_per_share: price, currency: "MXN", executed_at: days_ago.days.ago)
  end

  def close(price, days_ago:)
    create(:asset_price_history, asset: asset, date: days_ago.days.ago.to_date, close: price)
  end

  def data(period: nil) = described_class.call(user: user.reload, period: period)

  describe "the period selector" do
    it "defaults to a year" do
      expect(data[:period]).to eq("1A")
    end

    it "falls back to the default for a period it does not know" do
      expect(data(period: "../../etc/passwd")[:period]).to eq("1A")
    end

    it "honours a period it does know" do
      expect(data(period: "YTD")[:period]).to eq("YTD")
    end

    it "never starts before the portfolio existed" do
      portfolio.update!(inception_date: 10.days.ago.to_date)
      snapshot(20, 1_000)
      snapshot(5, 1_100)

      # MAX would otherwise reach back to the older snapshot.
      expect(data(period: "MAX")[:series].pluck(:date)).to all(be >= 10.days.ago.to_date)
    end
  end

  describe "the two chart series" do
    it "starts both lines together and separates them by the return" do
      snapshot(3, 1_000)
      snapshot(2, 1_100)

      series = data[:series]

      expect(series.first[:value]).to eq(1_000)
      expect(series.first[:contributed]).to eq(1_000)
      expect(series.last[:value]).to eq(1_100)
      expect(series.last[:contributed]).to eq(1_000)
    end

    it "raises the contributed line by the capital added, not by the gain" do
      snapshot(3, 1_000)
      buy(100, 10, days_ago: 2)
      snapshot(2, 2_100)

      series = data[:series]

      expect(series.last[:value]).to eq(2_100)
      expect(series.last[:contributed]).to eq(2_000)
    end

    it "returns nothing to draw with a single snapshot" do
      snapshot(2, 1_000)

      expect(data[:series]).to be_empty
    end
  end

  describe "¿Valió la pena?" do
    before do
      snapshot(60, 1_000)
      snapshot(1, 1_100)
    end

    it "compares against CETES reinvested over the period" do
      CetesRateHistory.record(term: "28", date: 2.years.ago.to_date, rate: 10.0)

      card = data[:vs_cetes]

      expect(card[:mine]).to be_within(0.01).of(10.0)
      expect(card[:benchmark]).to be > 0
      expect(card[:points]).to be_within(0.01).of(card[:mine] - card[:benchmark])
    end

    # The card must be able to say it cannot compare.
    it "is nil when no CETES rate precedes the period" do
      CetesRateHistory.record(term: "28", date: Date.current, rate: 10.0)

      expect(data[:vs_cetes]).to be_nil
    end

    it "is nil when the instance has never synced a rate" do
      expect(data[:vs_cetes]).to be_nil
    end
  end

  describe "vs sólo mantener" do
    # The position must predate the period, or there was nothing to hold.
    it "values the positions held at the start of the period at today's prices" do
      buy(100, 10, days_ago: 400)
      close(10, days_ago: 400)
      snapshot(60, 1_000)
      snapshot(1, 1_200)

      card = data[:vs_hold]

      # 100 shares worth 1,000 at the period's open, 12 each today.
      expect(card[:hold_value]).to eq(1_200)
      expect(card[:hold_return]).to be_within(0.01).of(20.0)
    end

    it "is nil when nothing was held at the start of the period" do
      snapshot(60, 0)
      snapshot(1, 1_000)

      expect(data[:vs_hold]).to be_nil
    end
  end

  describe "when the FX rate is missing" do
    it "degrades instead of raising, like every other screen" do
      usd = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)
      create(:position, portfolio: portfolio, asset: usd, shares: 5, avg_cost: 80, status: :open)

      result = data

      expect(result[:summary]).to be_nil
      expect(result[:fx_unavailable]).to be(true)
    end
  end

  it "returns an empty shape when there is no portfolio at all" do
    user.portfolio&.destroy

    result = described_class.call(user: user.reload)

    expect(result[:summary]).to be_nil
    expect(result[:fx_unavailable]).to be(false)
    expect(result[:series]).to be_empty
  end
end
