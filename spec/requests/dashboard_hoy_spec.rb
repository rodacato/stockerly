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

  describe "the ? on every figure" do
    def figures_with_help(body) = body.scan(%r{data-help-url="/help-opens/([a-z_]+)"}).flatten

    it "puts one on the verdict, the patrimonio and each kind of item" do
      held = mxn_asset(symbol: "WALMEX", current_price: 70)
      hold(held)
      create(:earnings_event, asset: held, report_date: 2.days.from_now.to_date)
      cetes = create(:asset, :fixed_income, symbol: "CETES28", currency: "MXN", current_price: 10)
      create(:position, portfolio: portfolio, asset: cetes, shares: 1_000, avg_cost: 10, status: :open,
                        maturity_date: 3.days.from_now.to_date)
      create(:watchlist_item, user: user, asset: mxn_asset(symbol: "NEAR", current_price: 100))
      create(:alert_rule, user: user, asset_symbol: "NEAR", threshold_value: 103)

      get dashboard_path

      expect(figures_with_help(response.body)).to include("veredicto", "patrimonio", "earnings", "maturity", "target")
    end

    it "puts one on the CETES comparison when there is one to show" do
      portfolio.update!(inception_date: 2.years.ago.to_date)
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))
      portfolio.snapshots.create!(date: 20.days.ago.to_date, currency: "MXN", total_value: 1_000)
      portfolio.snapshots.create!(date: 1.day.ago.to_date, currency: "MXN", total_value: 1_100)
      CetesRateHistory.record(term: "28", date: 2.years.ago.to_date, rate: 10.0)

      get dashboard_path

      expect(figures_with_help(response.body)).to include("vs_cetes")
      expect(response.body).to include(I18n.t("dashboard.hoy.vs_cetes_rotulo"))
    end

    it "explains each one in the catalogue's own words, without advice" do
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))

      get dashboard_path

      %w[veredicto patrimonio].each do |figure|
        expect(response.body).to include(I18n.t("dashboard.ayuda.#{figure}.cuerpo"))
      end
      expect(response.body).to include(I18n.t("dashboard.ayuda.veredicto.pie"))
    end

    it "keeps every catalogue entry free of imperative or advisory wording" do
      entries = I18n.t("dashboard.ayuda").except(:cerrar, :explicar).values.flat_map { |entry| entry.values }

      expect(entries.join(" ")).not_to match(/\b(compra|vende|te recomendamos|deberías|conviene)\b/i)
    end
  end

  describe "the plan" do
    include ActiveSupport::Testing::TimeHelpers

    def plan(**shares) = create(:plan, portfolio: portfolio, **{ stocks_share: 100, crypto_share: 0, fixed_income_share: 0 }.merge(shares))

    it "offers the first step quietly when there is no plan, and does not call a verdict on it" do
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))

      get dashboard_path

      expect(response.body).to include(I18n.t("dashboard.hoy.plan.sin_plan_titulo"))
      expect(response.body).to include(%(href="#{plan_path}"))
      expect(response.body).not_to include(I18n.t("dashboard.hoy.dentro_del_plan"))
    end

    it "says it is inside the plan when every share is near its target and nothing is planned to add" do
      plan(monthly_contribution: 0)
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))

      get dashboard_path

      expect(response.body).to include(I18n.t("dashboard.hoy.dentro_del_plan"))
      expect(response.body).to include(I18n.t("dashboard.hoy.plan.titulo"))
      expect(response.body).to include("100% de 100%")
    end

    it "names a gap against the plan in descriptive words" do
      plan(stocks_share: 25, crypto_share: 0, fixed_income_share: 75)
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))

      get dashboard_path

      expect(response.body).to include("Acciones y ETF: 100% vs 25% de tu plan")
      expect(response.body).to include("75 puntos arriba de lo que planeaste")
      expect(response.body).not_to include("Dentro de tu plan.")
    end

    it "flags a missing contribution only after the 10th" do
      plan
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))

      travel_to(Time.zone.local(2026, 10, 15, 12)) do
        get dashboard_path
        expect(response.body).to include(I18n.t("dashboard.hoy_item.contribution.titulo"))
      end

      travel_to(Time.zone.local(2026, 10, 5, 12)) do
        get dashboard_path
        expect(response.body).not_to include(I18n.t("dashboard.hoy_item.contribution.titulo"))
      end
    end

    it "keeps the plan card out of a stale-quote day" do
      plan
      hold(mxn_asset(symbol: "WALMEX", current_price: 70, price_updated_at: 6.days.ago))

      get dashboard_path

      expect(response.body).not_to include(I18n.t("dashboard.hoy.plan.titulo"))
      expect(response.body).not_to include(I18n.t("dashboard.hoy.dentro_del_plan"))
    end
  end

  describe "a central bank's decision" do
    include ActiveSupport::Testing::TimeHelpers

    def usd_asset(**attrs) = create(:asset, :stock, currency: "USD", **attrs)

    it "is an item when something held is quoted in the bank's currency" do
      travel_to(Time.zone.local(2026, 10, 26, 12)) do
        hold(usd_asset(symbol: "AAPL", current_price: 100))

        get dashboard_path

        expect(response.body).to include("Fed · FOMC en 2 días")
        expect(response.body).to include("fecha tentativa")
        expect(response.body).not_to include("Banxico ·")
      end
    end

    it "is not shown to someone who holds nothing in that currency" do
      travel_to(Time.zone.local(2026, 10, 26, 12)) do
        hold(mxn_asset(symbol: "WALMEX", current_price: 70))

        get dashboard_path

        expect(response.body).not_to include("Fed · FOMC")
      end
    end

    it "reads Banxico's decision for a peso holding" do
      travel_to(Time.zone.local(2026, 12, 15, 12)) do
        login_as(user)
        hold(mxn_asset(symbol: "WALMEX", current_price: 70))

        get dashboard_path

        expect(response.body).to include("Banxico · decisión de tasa en 2 días")
      end
    end

    it "says nothing when no decision is near" do
      travel_to(Time.zone.local(2026, 11, 20, 12)) do
        login_as(user)
        hold(mxn_asset(symbol: "WALMEX", current_price: 70))

        get dashboard_path

        expect(response.body).not_to include("decisión de tasa en")
      end
    end
  end

  describe "the headlines of what is tracked" do
    it "lists what was published for a holding, attributed, and leaves out the rest" do
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))
      create(:news_article, related_ticker: "WALMEX", title: "Walmex reports steady quarter", source: "Reuters", published_at: 2.hours.ago)
      create(:news_article, related_ticker: "TSLA", title: "Tesla unveils something", published_at: 1.hour.ago)

      get dashboard_path

      expect(response.body).to include(I18n.t("dashboard.show.titulares_titulo"))
      expect(response.body).to include("Walmex reports steady quarter")
      expect(response.body).to include("Reuters")
      expect(response.body).not_to include("Tesla unveils something")
    end

    it "shows no block when nothing was published" do
      hold(mxn_asset(symbol: "WALMEX", current_price: 70))

      get dashboard_path

      expect(response.body).not_to include(I18n.t("dashboard.show.titulares_titulo"))
    end
  end
end
