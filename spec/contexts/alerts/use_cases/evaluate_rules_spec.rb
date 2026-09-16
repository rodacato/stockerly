require "rails_helper"

RSpec.describe Alerts::UseCases::EvaluateRules do
  subject(:use_case) { described_class.new }

  let(:user) { create(:user) }
  let(:asset) { create(:asset, symbol: "AAPL", current_price: 150.0) }

  describe "#call" do
    context "when asset does not exist" do
      it "triggers nothing" do
        expect(use_case.call(asset_id: -1, new_price: "200.0")).to eq([])
      end
    end

    context "when no rules match" do
      before do
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 300, status: :active)
      end

      it "returns success with empty array" do
        result = use_case.call(asset_id: asset.id, new_price: "155.0")

        expect(result).to be_empty
      end
    end

    context "when a rule triggers" do
      let!(:rule) do
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 155, status: :active)
      end

      it "returns the triggered rules" do
        result = use_case.call(asset_id: asset.id, new_price: "160.0")

        expect(result).to include(rule)
      end

      it "publishes Alerts::Events::AlertRuleTriggered event" do
        allow(EventBus).to receive(:publish)

        use_case.call(asset_id: asset.id, new_price: "160.0")

        expect(EventBus).to have_received(:publish).with(
          an_instance_of(Alerts::Events::AlertRuleTriggered)
        )
      end
    end

    context "when a day-change rule triggers" do
      it "carries the measured move, so the notice can say which way it went" do
        create(:asset_price_history, asset: asset, date: 1.day.ago.to_date, close: 150.0)
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :day_change_percent, threshold_value: 5, status: :active)
        published = []
        EventBus.subscribe(Alerts::Events::AlertRuleTriggered, ->(event) { published << event })

        use_case.call(asset_id: asset.id, new_price: "141.0")

        expect(published.first.context[:day_change].to_d.round(2)).to eq(-6.0)
      end
    end

    context "when rule is paused" do
      before do
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 155, status: :paused)
      end

      it "ignores paused rules" do
        result = use_case.call(asset_id: asset.id, new_price: "160.0")

        expect(result).to be_empty
      end
    end
  end
end
