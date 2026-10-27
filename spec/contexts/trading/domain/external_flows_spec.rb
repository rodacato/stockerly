require "rails_helper"

RSpec.describe Trading::Domain::ExternalFlows do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 10) }

  subject(:flows) { described_class.new(portfolio.reload, currency: "MXN") }

  def trade(side, shares, price = 10, on: Time.current, which: asset)
    create(:trade, portfolio: portfolio, asset: which, side: side, shares: shares,
                   price_per_share: price, currency: which.currency, executed_at: on)
  end

  describe "#by_date" do
    it "sums buys as inflows and sells as outflows, per day" do
      trade(:buy, 100, on: 2.days.ago)
      trade(:buy, 50, on: 1.day.ago)
      trade(:sell, 20, on: 1.day.ago)

      result = flows.by_date(3.days.ago.to_date..Date.current)

      expect(result[2.days.ago.to_date]).to eq(1_000)
      expect(result[1.day.ago.to_date]).to eq(300)
    end

    it "answers zero for a day with no trades, without a nil" do
      expect(flows.by_date(3.days.ago.to_date..Date.current)[Date.current]).to eq(0)
    end

    it "ignores trades outside the range" do
      trade(:buy, 100, on: 30.days.ago)

      expect(flows.by_date(3.days.ago.to_date..Date.current)).to be_empty
    end

    it "ignores a discarded trade" do
      trade(:buy, 100, on: 1.day.ago).discard!

      expect(flows.by_date(3.days.ago.to_date..Date.current)[1.day.ago.to_date]).to eq(0)
    end

    it "converts a foreign trade at the rate captured on it" do
      usd = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)
      trade(:buy, 10, 100, on: 1.day.ago, which: usd).update!(fx_rate_at_execution: 17.0)

      expect(flows.by_date(3.days.ago.to_date..Date.current)[1.day.ago.to_date]).to eq(17_000)
    end

    # A year of daily sub-periods would otherwise ask once per day.
    it "reads the range in a single query regardless of how many days it spans" do
      10.times { |i| trade(:buy, 10, on: i.days.ago) }
      subject # resolve the lazy portfolio load outside the measured block

      expect { flows.by_date(30.days.ago.to_date..Date.current) }.to make_queries(at_most: 1)
    end
  end

  describe "#missed_by" do
    def snapshot(computed_at) = PortfolioSnapshot.new(date: Date.yesterday, updated_at: computed_at)

    it "counts trades recorded after the snapshot was computed, whatever date they carry" do
      computed_at = Time.current
      trade(:buy, 100, on: 5.days.ago)

      expect(flows.missed_by(snapshot(computed_at))).to eq(1_000)
    end

    it "ignores a trade recorded before it" do
      old = trade(:buy, 100, on: 5.days.ago)
      old.update_column(:created_at, 3.days.ago)

      expect(flows.missed_by(snapshot(Time.current))).to eq(0)
    end

    it "counts a trade dated after the snapshot's day, even if recorded before it was computed" do
      today = trade(:buy, 100, on: Time.current)
      today.update_column(:created_at, 1.hour.ago)

      expect(flows.missed_by(snapshot(Time.current))).to eq(1_000)
    end
  end
end
