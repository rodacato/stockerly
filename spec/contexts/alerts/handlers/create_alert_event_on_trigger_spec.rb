require "rails_helper"

RSpec.describe Alerts::Handlers::CreateAlertEventOnTrigger do
  include ActiveSupport::Testing::TimeHelpers

  describe ".call" do
    let(:user) { create(:user) }
    let(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 200.0) }

    it "creates an AlertEvent" do
      expect {
        described_class.call(
          alert_rule_id: rule.id,
          user_id: user.id,
          asset_symbol: "AAPL",
          triggered_price: "200.0"
        )
      }.to change(AlertEvent, :count).by(1)

      event = AlertEvent.last
      expect(event.alert_rule).to eq(rule)
      expect(event.asset_symbol).to eq("AAPL")
      expect(event.event_status).to eq("triggered")
    end

    it "writes a descriptive es-MX message per ADR-0001" do
      described_class.call(
        alert_rule_id: rule.id,
        user_id: user.id,
        asset_symbol: "AAPL",
        triggered_price: "210.0"
      )

      expect(AlertEvent.last.message).to include("AAPL cruzó USD 200.00 al alza")
    end

    it "stamps last_triggered_at on the rule so cooldown engages" do
      now = Time.current
      travel_to(now) do
        described_class.call(
          alert_rule_id: rule.id,
          user_id: user.id,
          asset_symbol: "AAPL",
          triggered_price: "210.0"
        )
      end
      expect(rule.reload.last_triggered_at).to be_within(1.second).of(now)
    end

    it "produces an MXN-aware message for .MX symbols" do
      mx_rule = create(:alert_rule, user: user, asset_symbol: "WALMEX.MX", condition: :price_crosses_below, threshold_value: 65.5)
      described_class.call(
        alert_rule_id: mx_rule.id,
        user_id: user.id,
        asset_symbol: "WALMEX.MX",
        triggered_price: "64.9"
      )
      expect(AlertEvent.last.message).to include("WALMEX.MX cruzó MXN 65.50 a la baja")
    end

    it "describes RSI oversold without action verbs" do
      rsi_rule = create(:alert_rule, user: user, asset_symbol: "NVDA", condition: :rsi_oversold, threshold_value: 30.0)
      described_class.call(
        alert_rule_id: rsi_rule.id,
        user_id: user.id,
        asset_symbol: "NVDA",
        triggered_price: "0"
      )
      msg = AlertEvent.last.message
      expect(msg).to include("NVDA aparece sobrevendido")
      expect(msg).not_to match(/comprar|vender|considera/i)
    end

    # Regression for #133 review: the publisher in EvaluateDateBasedRules
    # passes `result.rule.asset_symbol.to_s` which yields `""` (truthy, not
    # nil) for marketwide rules. `||=` would never fire and AlertEvent
    # would land with an empty asset_symbol. `.presence ||` covers it.
    it "falls back to BMV when an empty-string asset_symbol arrives for a bmv_holiday rule" do
      mw_rule = create(:alert_rule, :marketwide, user: user, condition: :bmv_holiday)
      described_class.call(
        alert_rule_id: mw_rule.id,
        user_id: user.id,
        asset_symbol: "",
        triggered_price: 3.days.from_now.to_date.to_s,
        context: { days_until: 3, holiday_name: "Festivo prueba" }
      )
      event = AlertEvent.last
      expect(event.asset_symbol).to eq("BMV")
      expect(event.message).to include("BMV cerrado en 3 día(s): Festivo prueba.")
    end

    it "falls back to CETES when an empty-string asset_symbol arrives for a cete_auction rule" do
      mw_rule = create(:alert_rule, :marketwide, user: user, condition: :cete_auction)
      described_class.call(
        alert_rule_id: mw_rule.id,
        user_id: user.id,
        asset_symbol: "",
        triggered_price: 3.days.from_now.to_date.to_s,
        context: { days_until: 3 }
      )
      event = AlertEvent.last
      expect(event.asset_symbol).to eq("CETES")
      expect(event.message).to include("Próxima subasta Banxico de CETES en 3 día(s).")
    end
  end
end
