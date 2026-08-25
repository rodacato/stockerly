require "rails_helper"

RSpec.describe "The asset detail's Mi posición tab", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 120, sync_status: :active) }

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
  end

  def hold(shares: 10, avg_cost: 100, bought_at: 17.0)
    position = create(:position, portfolio: portfolio, asset: asset, shares: shares,
                                 avg_cost: avg_cost, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy,
                   shares: shares, price_per_share: avg_cost, currency: "USD",
                   fx_rate_at_execution: bought_at, executed_at: 30.days.ago)
    position
  end

  it "shows no second tab for an asset you only watch" do
    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("posicion.tab_posicion"))
  end

  it "opens the tab once you hold it" do
    hold

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("posicion.tab_posicion"))
    expect(response.body).to include(I18n.t("posicion.tu_posicion"))
  end

  # The MXN-first differentiator: the asset and the peso are different stories.
  it "splits the gain between the asset and the peso" do
    hold

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("posicion.del_activo"))
    expect(response.body).to include(I18n.t("posicion.del_peso"))
  end

  it "omits the split for an asset in your own currency" do
    mxn = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70, sync_status: :active)
    position = create(:position, portfolio: portfolio, asset: mxn, shares: 100, avg_cost: 60, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: mxn, side: :buy, shares: 100,
                   price_per_share: 60, currency: "MXN", executed_at: 10.days.ago)

    get market_asset_path(mxn.symbol)

    expect(response.body).to include(I18n.t("posicion.tu_posicion"))
    expect(response.body).not_to include(I18n.t("posicion.del_peso"))
  end

  it "keeps the tab when the rate is missing, and says what it cannot split" do
    FxRate.delete_all
    hold

    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("posicion.sin_desglose"))
  end

  describe "the rules card" do
    # The artboard also showed a Meta; no target price exists in the code, so
    # the card carries the rules, which do.
    it "lists the rules you have on this asset" do
      hold
      create(:alert_rule, user: user, asset_symbol: "NVDA", condition: "rsi_overbought",
                          threshold_value: 70, status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("posicion.plan_titulo"))
      expect(response.body).to include("RSI(14) ≥ 70")
    end

    it "says you have none rather than showing an empty card" do
      hold

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("posicion.plan_sin_reglas"))
    end

    it "does not show another asset's rules" do
      hold
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "rsi_oversold", threshold_value: 30)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("posicion.plan_sin_reglas"))
    end
  end

  describe "the retrospective" do
    it "states the facts about how you entered, without grading them" do
      hold
      60.downto(0) { |i| create(:asset_price_history, asset: asset, date: i.days.ago.to_date, close: 100 + (i % 9)) }

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("posicion.retrospectiva_titulo"))
      expect(response.body).not_to match(/buen timing|mal timing|acertaste/i)
    end

    it "is absent when the buy predates the price history" do
      hold
      create(:asset_price_history, asset: asset, date: Date.current, close: 120)

      get market_asset_path(asset.symbol)

      expect(response.body).not_to include(I18n.t("posicion.retrospectiva_titulo"))
    end
  end
end
