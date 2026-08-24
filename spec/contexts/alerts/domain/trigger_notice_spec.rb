require "rails_helper"

RSpec.describe Alerts::Domain::TriggerNotice do
  def notice_for(rule, price: nil, symbol: rule.asset_symbol)
    described_class.new(rule: rule, asset_symbol: symbol, price: price)
  end

  describe "#title" do
    it "states what happened, with the threshold in its currency" do
      rule = build(:alert_rule, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 200)

      expect(notice_for(rule).title).to eq("AAPL cruzó USD 200.00 al alza")
    end

    it "uses MXN for BMV-listed symbols" do
      rule = build(:alert_rule, asset_symbol: "WALMEX.MX", condition: :price_crosses_below, threshold_value: 62.8)

      expect(notice_for(rule).title).to eq("WALMEX.MX cruzó MXN 62.80 a la baja")
    end

    it "delimits thousands instead of printing a bare decimal" do
      rule = build(:alert_rule, condition: :price_crosses_above, threshold_value: 1_318_400)

      expect(notice_for(rule).title).to include("USD 1,318,400.00")
    end

    it "drops the symbol for marketwide rules, which have none" do
      rule = build(:alert_rule, :marketwide, condition: :cete_auction)

      expect(notice_for(rule, symbol: nil).title).to eq("Banxico publicó una nueva subasta de CETES")
    end

    it "falls back to a generic line when the rule is already gone" do
      expect(notice_for(nil, symbol: "AAPL").title).to eq("Una de tus reglas se disparó")
    end
  end

  describe "#body" do
    it "carries the trigger price and the cooldown, never repeating the title" do
      rule   = build(:alert_rule, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 200, cooldown_minutes: 60)
      notice = notice_for(rule, price: "200.14")

      expect(notice.body).to eq("Al disparo: USD 200.14 · no vuelve a avisarte en 60 min")
      expect(notice.body).not_to include(notice.title)
    end

    it "omits the price when the condition has none to report" do
      rule = build(:alert_rule, :dividend, cooldown_minutes: 60)

      expect(notice_for(rule).body).to eq("no vuelve a avisarte en 60 min")
    end

    it "never renders an amount without its currency" do
      rule = build(:alert_rule, condition: :price_crosses_above, threshold_value: 200)

      expect(notice_for(rule, price: "200.14").body).to match(/\A[^\d]*(USD|MXN) /)
    end
  end

  describe "the descriptive contract (ADR-0001)" do
    it "never tells the user what to do" do
      imperatives = /\b(compra|vende|invierte|deber[íi]as|te conviene|aprovecha)\b/i

      Alerts::Domain::TriggerNotice::FALLBACK_TITLE.then { |t| expect(t).not_to match(imperatives) }

      AlertRule.conditions.each_key do |condition|
        rule   = build(:alert_rule, condition: condition, threshold_value: 70, window_days: 7)
        notice = notice_for(rule, price: "200.14")

        expect(notice.title).not_to match(imperatives), "title for #{condition}"
        expect(notice.body).not_to match(imperatives),  "body for #{condition}"
      end
    end
  end
end
