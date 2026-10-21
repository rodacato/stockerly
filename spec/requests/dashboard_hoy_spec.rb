require "rails_helper"

RSpec.describe "Hoy on the dashboard", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  def hold(asset) = create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

  def mxn_asset(**attrs) = create(:asset, :stock, currency: "MXN", **attrs)

  it "tells a first-run user there is nothing to orient yet, and offers the first trade" do
    get dashboard_path

    expect(response.body).to include("Aún no hay nada que orientar.")
    expect(response.body).to include(I18n.t("dashboard.hoy.primera_vez_titulo"))
    expect(response.body).not_to include("Todo en orden.")
  end

  it "says everything is in order only over current quotes with nothing to look at" do
    hold(mxn_asset(symbol: "WALMEX", current_price: 70))

    get dashboard_path

    expect(response.body).to include("Todo en orden.")
    expect(response.body).to include(I18n.t("dashboard.hoy.calma"))
  end

  it "never says everything is in order over a quote that is too old" do
    hold(mxn_asset(symbol: "WALMEX", current_price: 70, price_updated_at: 6.days.ago))

    get dashboard_path

    expect(response.body).to include("Sin cotizaciones al día.")
    expect(response.body).not_to include("Todo en orden.")
  end

  it "counts what is worth a look and lists each item with its own wording" do
    held = mxn_asset(symbol: "WALMEX", current_price: 70)
    hold(held)
    create(:earnings_event, asset: held, report_date: 2.days.from_now.to_date)
    cetes = create(:asset, :fixed_income, symbol: "CETES28", currency: "MXN", current_price: 10)
    create(:position, portfolio: portfolio, asset: cetes, shares: 1_000, avg_cost: 10, status: :open,
                      maturity_date: 3.days.from_now.to_date)
    watched = mxn_asset(symbol: "NEAR", current_price: 100)
    create(:watchlist_item, user: user, asset: watched)
    create(:alert_rule, user: user, asset_symbol: "NEAR", threshold_value: 103)

    get dashboard_path

    expect(response.body).to include("Hay 3 cosas de lo tuyo para mirar hoy.")
    expect(response.body).to include("CETES28 vence en 3 días")
    expect(response.body).to include("WALMEX reporta resultados")
    expect(response.body).to include("NEAR · falta 3.0% para tu objetivo")
    expect(response.body).to include("3 de 3")
  end

  it "keeps the compra / vende chips of the Señales block out of Hoy" do
    walmex = mxn_asset(symbol: "WALMEX", current_price: 70)
    hold(walmex)
    create(:technical_observation, asset: walmex)

    get dashboard_path
    hoy = response.body[/<section[^>]*aria-labelledby="hoy-veredicto".*?<\/section>/m]

    expect(response.body).to match(/compra/i)
    expect(hoy).not_to match(/compra|vende/i)
  end
end
