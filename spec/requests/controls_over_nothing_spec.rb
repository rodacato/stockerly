require "rails_helper"

# D142, the three instances the rule was written from. The rule is in
# docs/architecture/conventions.md; each pair here is the positive case and
# the negative that keeps the rule from over-firing.
RSpec.describe "Controls over nothing", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }

  before { login_as(user) }

  describe "the Reglas counters" do
    it "does not report zero rules above the invitation to create the first" do
      get alerts_path

      expect(response.body).not_to include(I18n.t("alerts.index.disparadas_hoy"))
      expect(response.body).not_to include(I18n.t("alerts.index.reglas_activas"))
    end

    it "reports them once there are rules to count" do
      create(:alert_rule, user: user, asset_symbol: "AAPL")

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.disparadas_hoy"))
      expect(response.body).to include(I18n.t("alerts.index.reglas_activas"))
    end

    # Negative: a paused rule is still a rule, so the counters have something
    # to say even when the active count is the zero on screen.
    it "reports them for a paused rule, whose zero is a reading and not an absence" do
      create(:alert_rule, :paused, user: user, asset_symbol: "AAPL")

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.reglas_activas"))
    end
  end

  describe "the inbox filter chips" do
    it "does not offer four buckets of an inbox that has nothing in it" do
      get notifications_path

      expect(response.body).not_to include(I18n.t("notifications.index.alertas"))
      expect(response.body).to include(I18n.t("notifications.index.vacio"))
    end

    # Negative, and the one the rule was narrowed for: an empty bucket is not
    # an empty inbox, so the chips stay when the filter is what emptied it.
    it "keeps them when the selected bucket is empty but the inbox is not" do
      create(:notification, user: user, notification_type: :alert_triggered)

      get notifications_path(tipo: "cetes")

      expect(response.body).to include(I18n.t("notifications.index.alertas"))
      expect(response.body).to include(I18n.t("notifications.index.sin_coincidencias"))
    end
  end

  describe "the Consolidado period selector" do
    let(:portfolio) do
      (user.portfolio || create(:portfolio, user: user)).tap { |p| p.update!(inception_date: 2.years.ago.to_date) }
    end

    it "does not offer five periods over a chart that has no history to cut" do
      get portfolio_path

      expect(response.body).to include(I18n.t("portfolios.show.sin_historial_titulo"))
      expect(response.body).not_to include(%(href="#{portfolio_path(period: '3M')}"))
    end

    it "offers them once there is a curve for them to cut" do
      asset = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 12)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 10, status: :open)
      portfolio.snapshots.create!(date: 60.days.ago.to_date, currency: "MXN", total_value: 1_000)
      portfolio.snapshots.create!(date: 1.day.ago.to_date, currency: "MXN", total_value: 1_200)

      get portfolio_path

      expect(response.body).to include(%(href="#{portfolio_path(period: '3M')}"))
    end
  end
end
