require "rails_helper"

RSpec.describe Alerts::Handlers::RecordRuleCreatedActivity do
  describe ".call" do
    let(:user) { create(:user) }

    let(:event) do
      Alerts::Events::RuleCreated.new(
        rule_id: 1, user_id: user.id, asset_symbol: "AAPL", condition: "price_above"
      )
    end

    it "records an alert_rule_created activity" do
      expect {
        described_class.call(event)
      }.to change(UserActivity, :count).by(1)

      activity = UserActivity.last
      expect(activity.user).to eq(user)
      expect(activity.action).to eq("alert_rule_created")
      expect(activity.params).to eq("asset_symbol" => "AAPL", "condition" => "price_above")
    end

    it "handles a nil asset_symbol (sentiment-based rule with no symbol)" do
      event = Alerts::Events::RuleCreated.new(
        rule_id: 2, user_id: user.id, asset_symbol: nil, condition: "sentiment_below"
      )

      described_class.call(event)
      expect(UserActivity.last.params["asset_symbol"]).to eq("")
    end

    it "subscribes via EventBus and fires on RuleCreated publish" do
      load Rails.root.join("config/initializers/event_subscriptions.rb")

      expect {
        EventBus.publish(event)
      }.to change(UserActivity.by_action("alert_rule_created"), :count).by(1)
    end
  end
end
