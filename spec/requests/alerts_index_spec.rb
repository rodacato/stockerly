require "rails_helper"

RSpec.describe "Reglas", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }

  before { login_as(user) }

  # D143: the preference switches are configuration set once, so they live on
  # the hub that owns configuration. Reglas keeps a line and a door.
  describe "where notification preferences live" do
    it "does not render the switches on the screen that only reads outcomes" do
      get alerts_path

      expect(response.body).not_to include(%(data-toggle-url-value="#{update_preferences_path}"))
      expect(response.body).not_to include(I18n.t("settings.show.digest"))
    end

    it "points at Ajustes instead" do
      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.avisos_nota"))
      expect(response.body).to include(%(href="#{settings_path}"))
    end

    # Negative: the hub is where the panel belongs, so it has to still be there.
    it "keeps the panel on the hub that owns it" do
      get settings_path

      expect(response.body).to include(%(data-toggle-url-value="#{update_preferences_path}"))
      expect(response.body).to include(I18n.t("settings.show.digest"))
    end
  end

  describe "the heading ranks" do
    it "gives Tus reglas the only primary rank on the screen" do
      get alerts_path

      expect(response.body).to match(
        %r{<h2 class="font-display text-2xl font-bold text-fg-default">\s*#{I18n.t('alerts.index.tus_reglas')}\s*</h2>}
      )
      expect(response.body.scan(/font-display text-2xl font-bold/).size).to eq(1)
    end
  end

  describe "editing a rule in place" do
    let!(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_below", threshold_value: 150.0, cooldown_minutes: 60) }

    before { create(:asset, symbol: "AAPL") }

    it "links each rule card to its edit sheet" do
      get alerts_path

      expect(response.body).to include(%(href="#{edit_alert_path(rule)}"))
    end

    it "renders the form prefilled and pointed at update" do
      get edit_alert_path(rule)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{alert_path(rule)}"))
      expect(response.body).to include('name="_method" value="patch"')
      expect(response.body).to include('value="AAPL"')
      expect(response.body).to include(I18n.t("alerts.new.titulo_editar"))
      expect(response.body).to match(/value="price_crosses_below"\s+checked/)
    end

    it "keeps the create form pointed at create" do
      get new_alert_path

      expect(response.body).to include(%(action="#{alerts_path}"))
      expect(response.body).not_to include('name="_method" value="patch"')
    end

    it "changes the threshold and keeps the rule with its history" do
      rule.update!(last_triggered_at: 2.days.ago)

      patch alert_path(rule), params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_below", threshold_value: 210, cooldown_minutes: 15 } }

      expect(response).to redirect_to(alerts_path)
      expect(rule.reload.threshold_value).to eq(210)
      expect(rule.cooldown_minutes).to eq(15)
      expect(rule.last_triggered_at).to be_present
    end

    it "leaves the rule untouched and flashes the error when validation fails" do
      patch alert_path(rule), params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_below", threshold_value: "" } }

      expect(response).to redirect_to(alerts_path)
      expect(flash[:alert]).to be_present
      expect(rule.reload.threshold_value).to eq(150.0)
    end

    context "when the rule belongs to someone else" do
      let(:other) { create(:user, email: "other@example.com") }
      let!(:foreign) { create(:alert_rule, user: other, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 99.0) }

      it "answers 404 for the edit sheet" do
        get edit_alert_path(foreign)

        expect(response).to have_http_status(:not_found)
      end

      it "does not update it" do
        patch alert_path(foreign), params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 1 } }

        expect(flash[:alert]).to eq(I18n.t("alerts.flash.no_encontrada"))
        expect(foreign.reload.threshold_value).to eq(99.0)
      end
    end
  end

  describe "when a rule is next checked" do
    before { create(:asset, symbol: "AAPL") }

    it "says how often an active price rule is evaluated" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200)

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.revision_precio", minutes: 5))
    end

    it "says the daily time for an active date rule" do
      create(:alert_rule, :dividend, user: user, asset_symbol: "AAPL", window_days: 3)

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.revision_diaria", time: "7:30"))
    end

    # Negative: a paused rule is not being checked, so it must not claim to be.
    it "shows no line on a paused rule" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200, status: :paused)

      get alerts_path

      expect(response.body).not_to include(I18n.t("alerts.index.revision_precio", minutes: 5))
    end
  end

  describe "what a rule's indicator means" do
    before { create(:asset, symbol: "AAPL") }

    it "explains an RSI rule with the threshold it holds" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "rsi_overbought", threshold_value: 72)

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.sugerencias.rsi_overbought.porque", threshold: 72))
      expect(response.body).to include('data-controller="metric-tooltip"')
    end

    it "explains a day-change rule with its percentage" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "day_change_percent", threshold_value: 5)

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.sugerencias.day_change_percent.porque", percent: "5"))
    end

    # Negative: no copy for the condition, so no icon and no popover.
    it "renders no explainer for a condition without an entry" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200)

      get alerts_path

      expect(response.body).not_to include("metric-tooltip")
    end

    it "keeps the empty-state suggestions explaining themselves" do
      create(:position, portfolio: create(:portfolio, user: user), asset: Asset.find_by!(symbol: "AAPL"), shares: 10, avg_cost: 100)

      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.sugerencias.day_change_percent.porque", percent: "5"))
    end
  end
end
