require "rails_helper"

RSpec.describe Trading::UseCases::AssemblePanorama do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  def mxn_asset(**attrs) = create(:asset, :stock, currency: "MXN", **attrs)

  describe "the patrimonio strip" do
    it "consolidates when the rate is there" do
      portfolio.update!(buying_power: 0)
      asset = mxn_asset(symbol: "WALMEX", current_price: 70)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      data = described_class.call(user: user)

      expect(data[:summary].total_value).to eq(7_000)
      expect(data[:fx_unavailable]).to be(false)
    end

    # The bug this slice exists to kill: /dashboard raised on exactly this
    # setup, and it raised inside the template because the old use case built
    # the summary without ever valuing it.
    it "reports that it cannot consolidate instead of raising" do
      asset = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)
      create(:position, portfolio: portfolio, asset: asset, shares: 5, avg_cost: 80, status: :open)

      data = described_class.call(user: user)

      expect(data[:summary]).to be_nil
      expect(data[:fx_unavailable]).to be(true)
    end

    it "does not claim a missing rate when there is no portfolio at all" do
      user.portfolio&.destroy
      user.reload

      expect(described_class.call(user: user)[:fx_unavailable]).to be(false)
    end
  end

  describe "the sentiment carousel" do
    it "carries the move since the previous reading, not since the previous row" do
      create(:fear_greed_reading, index_type: "crypto", value: 68, fetched_at: 1.day.ago)
      create(:fear_greed_reading, index_type: "crypto", value: 72, fetched_at: 1.hour.ago)

      card = described_class.call(user: user)[:sentiment_cards].find { |c| c.key == :crypto }

      expect(card.value).to eq(72)
      expect(card.delta).to eq(4)
    end

    it "reports no delta when today is the only reading" do
      create(:fear_greed_reading, index_type: "crypto", value: 72, fetched_at: 1.hour.ago)

      card = described_class.call(user: user)[:sentiment_cards].find { |c| c.key == :crypto }

      expect(card.delta).to be_nil
    end

    it "drops a card the instance has never fetched rather than inventing a 50" do
      create(:fear_greed_reading, index_type: "crypto", value: 72, fetched_at: 1.hour.ago)

      keys = described_class.call(user: user)[:sentiment_cards].map(&:key)

      expect(keys).to eq([ :crypto ])
    end

    it "adds the watchlist card once something is watched" do
      asset = mxn_asset(symbol: "NVDA")
      create(:watchlist_item, user: user, asset: asset)
      create(:trend_score, asset: asset, score: 61, calculated_at: 1.hour.ago)

      card = described_class.call(user: user)[:sentiment_cards].find { |c| c.key == :watchlist }

      expect(card.value).to eq(61)
      expect(card.label_key).to eq("bullish")
    end
  end

  describe "the radar" do
    it "leaves out an asset that did not move" do
      still = mxn_asset(symbol: "QUIET", current_price: 10, change_percent_24h: 0)
      moved = mxn_asset(symbol: "LOUD", current_price: 10, change_percent_24h: 3.2)
      create(:position, portfolio: portfolio, asset: still, shares: 1, avg_cost: 10, status: :open)
      create(:position, portfolio: portfolio, asset: moved, shares: 1, avg_cost: 10, status: :open)

      expect(described_class.call(user: user)[:radar].map { |e| e.asset.symbol }).to eq([ "LOUD" ])
    end

    it "orders by how far it moved, in either direction" do
      small = mxn_asset(symbol: "SMALL", change_percent_24h: 1.0)
      big   = mxn_asset(symbol: "BIG",   change_percent_24h: -8.0)
      [ small, big ].each { |a| create(:position, portfolio: portfolio, asset: a, shares: 1, avg_cost: 1, status: :open) }

      expect(described_class.call(user: user)[:radar].map { |e| e.asset.symbol }).to eq([ "BIG", "SMALL" ])
    end

    # A CETES that does not move is precisely the row the design shows, because
    # what makes it news is the maturity date.
    it "keeps a fixed-income position that is about to mature even though it is flat" do
      cetes = create(:asset, :fixed_income, symbol: "CETES28", currency: "MXN", change_percent_24h: 0)
      create(:position, portfolio: portfolio, asset: cetes, shares: 1, avg_cost: 10,
                        status: :open, maturity_date: 3.days.from_now.to_date)

      entry = described_class.call(user: user)[:radar].first

      expect(entry.asset.symbol).to eq("CETES28")
      expect(entry.maturity_days).to eq(3)
    end

    it "ignores a maturity too far out to be news" do
      cetes = create(:asset, :fixed_income, symbol: "CETES91", currency: "MXN", change_percent_24h: 0)
      create(:position, portfolio: portfolio, asset: cetes, shares: 1, avg_cost: 10,
                        status: :open, maturity_date: 200.days.from_now.to_date)

      expect(described_class.call(user: user)[:radar]).to be_empty
    end

    it "mixes what you own with what you watch" do
      held    = mxn_asset(symbol: "HELD", change_percent_24h: 2.0)
      watched = mxn_asset(symbol: "WATCHED", change_percent_24h: 5.0)
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      create(:watchlist_item, user: user, asset: watched)

      radar = described_class.call(user: user)[:radar]

      expect(radar.map { |e| e.asset.symbol }).to eq([ "WATCHED", "HELD" ])
      expect(radar.map(&:kind)).to eq([ :watchlist, :position ])
    end
  end
end
