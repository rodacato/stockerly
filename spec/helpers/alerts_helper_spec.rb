require "rails_helper"

RSpec.describe AlertsHelper, type: :helper do
  describe "#alert_condition_summary" do
    it "names the volume window the evaluator actually averages over" do
      rule = build(:alert_rule, condition: :volume_spike, threshold_value: 3)

      expect(helper.alert_condition_summary(rule))
        .to eq("volumen 3× o más sobre su promedio de #{Alerts::Domain::AlertEvaluator::VOLUME_AVERAGE_DAYS} días")
    end

    it "states day-change and RSI thresholds as inclusive, like the evaluator's >=" do
      expect(helper.alert_condition_summary(build(:alert_rule, condition: :day_change_percent, threshold_value: 6)))
        .to eq("se mueve 6% o más en el día")
      expect(helper.alert_condition_summary(build(:alert_rule, condition: :rsi_overbought, threshold_value: 70)))
        .to eq("RSI(14) en 70 o más")
    end
  end

  describe "#alert_rule_kind_label" do
    it "labels a crypto rule as Cripto, not as a stock" do
      create(:asset, :crypto, symbol: "BTC")
      rule = build(:alert_rule, asset_symbol: "BTC")

      expect(helper.alert_rule_kind_label(rule)).to eq("Cripto")
    end

    it "labels an ETF from its asset type" do
      create(:asset, symbol: "VOO", asset_type: :etf)
      rule = build(:alert_rule, asset_symbol: "VOO")

      expect(helper.alert_rule_kind_label(rule)).to eq("ETF")
    end

    it "keeps the MX suffix on a BMV-listed stock" do
      create(:asset, symbol: "WALMEX.MX", asset_type: :stock)
      rule = build(:alert_rule, asset_symbol: "WALMEX.MX")

      expect(helper.alert_rule_kind_label(rule)).to eq("Acción MX")
    end

    it "falls back to the symbol heuristic when the rule outlived its asset" do
      rule = build(:alert_rule, asset_symbol: "GOOGL")

      expect(helper.alert_rule_kind_label(rule)).to eq("Acción")
    end

    it "still reads marketwide conditions off the condition" do
      expect(helper.alert_rule_kind_label(build(:alert_rule, :marketwide, condition: :cete_auction))).to eq("CETES")
      expect(helper.alert_rule_kind_label(build(:alert_rule, :marketwide, condition: :bmv_holiday))).to eq("BMV")
    end

    it "queries each distinct symbol once across a table of rules" do
      create(:asset, :crypto, symbol: "BTC")
      rules = Array.new(3) { build(:alert_rule, asset_symbol: "BTC") }

      queries = 0
      counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        rules.each { |rule| helper.alert_rule_kind_label(rule) }
      end

      expect(queries).to eq(1)
    end
  end
end
