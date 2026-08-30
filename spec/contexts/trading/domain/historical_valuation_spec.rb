require "rails_helper"

RSpec.describe Trading::Domain::HistoricalValuation do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70) }

  def buy(shares, price, on:, which: asset)
    create(:trade, portfolio: portfolio, asset: which, side: :buy, shares: shares,
                   price_per_share: price, currency: which.currency, executed_at: on)
  end

  def sell(shares, price, on:, which: asset)
    create(:trade, portfolio: portfolio, asset: which, side: :sell, shares: shares,
                   price_per_share: price, currency: which.currency, executed_at: on)
  end

  def close(price, on:, which: asset)
    create(:asset_price_history, asset: which, date: on, close: price)
  end

  def valuation = described_class.new(portfolio.reload, currency: "MXN")

  describe "#shares_on" do
    it "counts only trades executed on or before the date" do
      buy(100, 50, on: 10.days.ago)
      buy(50, 60, on: 2.days.ago)

      expect(valuation.shares_on(5.days.ago.to_date).values).to eq([ 100 ])
      expect(valuation.shares_on(Date.current).values).to eq([ 150 ])
    end

    it "subtracts sells" do
      buy(100, 50, on: 10.days.ago)
      sell(40, 55, on: 3.days.ago)

      expect(valuation.shares_on(Date.current).values).to eq([ 60 ])
    end

    it "drops an asset sold out entirely" do
      buy(100, 50, on: 10.days.ago)
      sell(100, 55, on: 3.days.ago)

      expect(valuation.shares_on(Date.current)).to be_empty
    end
  end

  describe "#market_value_on" do
    it "values the shares held at that date, at that date's close" do
      buy(100, 50, on: 10.days.ago)
      close(50, on: 10.days.ago.to_date)
      close(80, on: Date.current)

      expect(valuation.market_value_on(10.days.ago.to_date)).to eq(5_000)
      expect(valuation.market_value_on(Date.current)).to eq(8_000)
    end

    # Markets are shut on weekends; an exact-date lookup would value them at zero.
    it "falls back to the last close on or before a day with no data" do
      buy(100, 50, on: 10.days.ago)
      close(50, on: 10.days.ago.to_date)

      expect(valuation.market_value_on(5.days.ago.to_date)).to eq(5_000)
    end

    it "values at zero when no close exists on or before the date" do
      buy(100, 50, on: 10.days.ago)
      close(50, on: Date.current)

      expect(valuation.market_value_on(8.days.ago.to_date)).to eq(0)
    end

    # The reason AC4 exists. SplitAdjuster rewrites trades into post-split terms
    # but leaves asset_price_histories alone, so an unadjusted close doubles the
    # answer for every date before the split.
    it "adjusts a pre-split close so it matches post-split shares" do
      buy(200, 50, on: 10.days.ago)                 # 100 @ 100 pre-split, as SplitAdjuster left it
      close(100, on: 10.days.ago.to_date)           # the close of that day, in its own terms
      create(:stock_split, asset: asset, ex_date: 5.days.ago.to_date, ratio_from: 1, ratio_to: 2)

      expect(valuation.market_value_on(10.days.ago.to_date)).to eq(10_000)
    end

    it "composes two splits by multiplication, not addition" do
      buy(400, 25, on: 10.days.ago)
      close(100, on: 10.days.ago.to_date)
      create(:stock_split, asset: asset, ex_date: 5.days.ago.to_date, ratio_from: 1, ratio_to: 2)
      create(:stock_split, asset: asset, ex_date: 3.days.ago.to_date, ratio_from: 1, ratio_to: 2)

      expect(valuation.market_value_on(10.days.ago.to_date)).to eq(10_000)
    end

    it "leaves a close after the split alone" do
      buy(200, 50, on: 10.days.ago)
      create(:stock_split, asset: asset, ex_date: 5.days.ago.to_date, ratio_from: 1, ratio_to: 2)
      close(50, on: 2.days.ago.to_date)

      expect(valuation.market_value_on(2.days.ago.to_date)).to eq(10_000)
    end

    it "converts a foreign holding at the rate of that date" do
      usd = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)
      buy(10, 100, on: 10.days.ago, which: usd)
      close(100, on: 10.days.ago.to_date, which: usd)
      FxRateHistory.record(base: "USD", quote: "MXN", date: 10.days.ago.to_date, rate: 18.0)

      expect(valuation.market_value_on(10.days.ago.to_date)).to eq(18_000)
    end
  end
end
