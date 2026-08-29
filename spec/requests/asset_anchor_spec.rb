require "rails_helper"

# The Análisis anchor and the 52-week range: what the current price is read
# against. CKP-8 / CKP-9, decided as D67. The artboard puts both on Análisis;
# the rules card used to live on Mi posición and its specs moved here with it.
RSpec.describe "The asset detail's price anchor", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 120, sync_status: :active) }

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
  end

  def hold(avg_cost: 100)
    create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: avg_cost, status: :open)
  end

  def with_range(low:, high:)
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
                               metrics: { "fifty_two_week_low" => low.to_s, "fifty_two_week_high" => high.to_s })
  end

  describe "vs. tu plan" do
    it "reads the price against your average cost when you hold it" do
      hold(avg_cost: 100)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.vs_plan.titulo"))
      expect(response.body).to include("+20.0%")
    end

    it "reads the price against your alert threshold when you only watch it" do
      create(:alert_rule, user: user, asset_symbol: "NVDA", condition: "price_crosses_below",
                          threshold_value: 100, status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.vs_plan.titulo"))
      expect(response.body).to include(I18n.t("market.vs_plan.umbral_baja", percent: "16.7%"))
    end

    it "lists a rule that carries no price beside the anchor" do
      hold
      create(:alert_rule, user: user, asset_symbol: "NVDA", condition: "rsi_overbought",
                          threshold_value: 70, status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).to include("RSI(14) ≥ 70")
    end

    it "does not show another asset's rules" do
      hold
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "rsi_oversold", threshold_value: 30)

      get market_asset_path(asset.symbol)

      expect(response.body).not_to include("RSI(14) ≤ 30")
    end

    # The block is absent rather than empty: with nothing to anchor against,
    # a card reading "no tienes reglas" is a prompt, not a reading.
    it "renders nothing at all when there is neither a position nor a rule" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t("market.vs_plan.titulo"))
    end
  end

  describe "the 52-week range" do
    it "places the price between the year's bounds" do
      with_range(low: 80, high: 200)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.range_52w.titulo"))
      expect(response.body).to include(I18n.t("market.range_52w.low", percent: "50.0%"))
    end

    it "says the price is above its high rather than claiming it is near it" do
      with_range(low: 80, high: 100)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.range_52w.above_high", percent: "20.0%"))
    end

    it "renders nothing when the provider never filled the bounds" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t("market.range_52w.titulo"))
    end
  end
end
