require "rails_helper"

RSpec.describe Trading::UseCases::LoadAssets do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  def mxn_asset(**attrs) = create(:asset, :stock, currency: "MXN", **attrs)

  def hold(asset, shares:)
    create(:position, portfolio: portfolio, asset: asset, shares: shares, avg_cost: 1, status: :open)
  end

  def symbols_of(tab)
    data = described_class.call(user: user, tab: tab)
    (tab == "watchlist" ? data[:watchlist_items] : data[:positions]).map { |row| row.asset.symbol }
  end

  describe "Cartera's order (D68)" do
    it "leads with the largest holding, not with insertion order" do
      hold(mxn_asset(symbol: "SMALL", current_price: 10), shares: 1)
      hold(mxn_asset(symbol: "BIG", current_price: 10), shares: 100)
      hold(mxn_asset(symbol: "MID", current_price: 10), shares: 10)

      expect(symbols_of("cartera")).to eq(%w[BIG MID SMALL])
    end

    it "compares holdings across currencies in the declared one" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 18)
      hold(create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100), shares: 10)
      hold(mxn_asset(symbol: "WALMEX", current_price: 70), shares: 100)

      expect(symbols_of("cartera")).to eq(%w[AAPL WALMEX])
    end

    it "retreats to alphabetical by symbol when a rate is missing" do
      hold(create(:asset, :stock, symbol: "ZETA", currency: "USD", current_price: 1_000), shares: 10)
      hold(mxn_asset(symbol: "AMXL", current_price: 1), shares: 1)

      expect(symbols_of("cartera")).to eq(%w[AMXL ZETA])
    end

    # The screen has to list what you hold on a day Banxico is late; only the
    # consolidation is impossible.
    it "still returns every holding when the conversion cannot be done" do
      hold(create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100), shares: 5)
      hold(mxn_asset(symbol: "WALMEX", current_price: 70), shares: 100)

      data = described_class.call(user: user, tab: "cartera")

      expect(data[:fx_unavailable]).to be(true)
      expect(data[:positions].map { |p| p.asset.symbol }).to eq(%w[AAPL WALMEX])
    end

    it "does not reshuffle one screen against the next while the rate is gone" do
      hold(create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100), shares: 5)
      hold(mxn_asset(symbol: "WALMEX", current_price: 70), shares: 100)

      expect(symbols_of("cartera")).to eq(symbols_of("cartera"))
    end
  end

  describe "the Watchlist's order (D68)" do
    def watch(symbol, price:, change: 0.0, currency: "MXN")
      asset = create(:asset, :stock, symbol: symbol, currency: currency,
                                     current_price: price, change_percent_24h: change)
      create(:watchlist_item, user: user, asset: asset, entry_price: price)
      asset
    end

    def rule(symbol, threshold, **attrs)
      create(:alert_rule, user: user, asset_symbol: symbol, threshold_value: threshold, **attrs)
    end

    it "puts what is closest to its own threshold on top" do
      watch("FAR", price: 100)
      watch("NEAR", price: 100)
      rule("FAR", 130)
      rule("NEAR", 104)

      expect(symbols_of("watchlist")).to eq(%w[NEAR FAR])
    end

    # 182.50 USD against 8.42 MXN is not a comparison the watchlist can make
    # (D10), so the cheap price sort is the one thing this must not become.
    it "never falls back to comparing prices across currencies" do
      watch("CHEAP", price: 8.42, currency: "MXN")
      watch("PRICEY", price: 182.50, currency: "USD")
      rule("CHEAP", 12.63)
      rule("PRICEY", 191.62)

      expect(symbols_of("watchlist")).to eq(%w[PRICEY CHEAP])
    end

    it "ranks a row with no rule by how far it moved, behind every row with one" do
      watch("RULED", price: 100, change: 0.1)
      watch("QUIET", price: 100, change: 1.0)
      watch("LOUD", price: 100, change: -9.0)
      rule("RULED", 900)

      expect(symbols_of("watchlist")).to eq(%w[RULED LOUD QUIET])
    end

    it "ignores a paused rule" do
      watch("PAUSED", price: 100, change: 0.1)
      watch("MOVER", price: 100, change: 5.0)
      rule("PAUSED", 101, status: :paused)

      expect(symbols_of("watchlist")).to eq(%w[MOVER PAUSED])
    end

    # threshold_value on an RSI rule is an index level, not a price.
    it "ignores a rule whose threshold is not a price" do
      watch("RSI", price: 100, change: 0.1)
      watch("MOVER", price: 100, change: 5.0)
      rule("RSI", 70, condition: :rsi_overbought)

      expect(symbols_of("watchlist")).to eq(%w[MOVER RSI])
    end

    it "reads the nearest of several rules on the same symbol" do
      watch("MULTI", price: 100)
      watch("SINGLE", price: 100)
      rule("MULTI", 300)
      rule("MULTI", 102, condition: :price_crosses_below)
      rule("SINGLE", 110)

      expect(symbols_of("watchlist")).to eq(%w[MULTI SINGLE])
    end

    it "falls back to movement for an asset with no price to measure against" do
      watch("NOPRICE", price: nil, change: 3.0)
      watch("PRICED", price: 100, change: 0.5)
      rule("NOPRICE", 50)
      rule("PRICED", 101)

      expect(symbols_of("watchlist")).to eq(%w[PRICED NOPRICE])
    end
  end
end
