require "rails_helper"

RSpec.describe "Consolidado", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user)).tap { |p| p.update!(inception_date: 2.years.ago.to_date) }
  end
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 12) }

  before { login_as(user) }

  def snapshot(days_ago, value)
    portfolio.snapshots.create!(date: days_ago.days.ago.to_date, currency: "MXN",
                                total_value: value, invested_value: value)
  end

  def with_history
    create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 10, status: :open)
    snapshot(60, 1_000)
    snapshot(1, 1_200)
  end

  describe "GET /portfolio" do
    it "renders the four blocks" do
      with_history
      CetesRateHistory.record(term: "28", date: 2.years.ago.to_date, rate: 10.0)

      get portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("PATRIMONIO TOTAL · MXN")
      expect(response.body).to include(I18n.t("portfolios.show.como_ha_ido"))
      expect(response.body).to include(I18n.t("portfolios.show.valio_la_pena"))
      expect(response.body).to include(I18n.t("portfolios.show.como_repartido"))
    end

    # D2 finally earns its debut: this is the chart PriceChartController was
    # written for, with two series rather than a 60px sparkline.
    it "mounts the chart with both series" do
      with_history

      get portfolio_path

      expect(response.body).to include('data-controller="chart"')
      expect(response.body).to include("--color-positive")
      expect(response.body).to include("--color-border-strong")
    end

    it "does not offer a cash breakdown the instance cannot back" do
      with_history

      get portfolio_path

      expect(response.body).not_to include("Disponible")
      expect(response.body).not_to include("Saldo disponible")
    end

    it "says there is no curve rather than drawing an empty one" do
      get portfolio_path

      expect(response.body).to include(I18n.t("portfolios.show.sin_historial_titulo"))
      expect(response.body).not_to include('data-controller="chart"')
    end
  end

  describe "the comparison cards" do
    it "says it cannot compare when no CETES rate precedes the period" do
      with_history

      get portfolio_path

      expect(response.body).to include(I18n.t("portfolios.show.sin_comparacion"))
    end

    it "states the time-weighted caveat whenever a card has a figure" do
      with_history
      CetesRateHistory.record(term: "28", date: 2.years.ago.to_date, rate: 10.0)

      get portfolio_path

      expect(response.body).to include(I18n.t("portfolios.show.twr_nota"))
    end
  end

  describe "the period selector" do
    it "honours the period asked for" do
      with_history

      get portfolio_path(period: "3M")

      expect(response.body).to include(I18n.t("portfolios.show.periodo.m3"))
      expect(response).to have_http_status(:ok)
    end

    it "does not break on a period it does not know" do
      get portfolio_path(period: "../../etc/passwd")

      expect(response).to have_http_status(:ok)
    end
  end

  describe "when the FX rate is missing" do
    it "degrades rather than raising" do
      usd = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)
      create(:position, portfolio: portfolio, asset: usd, shares: 5, avg_cost: 80, status: :open)

      get portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("comun.sin_tc_titulo"))
    end
  end

  describe "the lists the Consolidado does not carry" do
    it "keeps all four tabs reachable at /positions" do
      with_history

      %w[open closed dividends trades].each do |tab|
        get positions_path(tab: tab)
        expect(response).to have_http_status(:ok), "#{tab} tab is gone"
      end
    end

    # Slice 1's precedent: routable, with no nav entry, as a decision.
    it "has no entry in the shell nav" do
      get portfolio_path

      expect(response.body).not_to include(%(href="#{positions_path}"))
    end
  end
end
