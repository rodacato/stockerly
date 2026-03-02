require "rails_helper"

RSpec.describe Notifications::CreateNotification do
  subject(:use_case) { described_class.new }

  let(:user) { create(:user) }

  describe "#call" do
    context "when user does not exist" do
      it "returns failure" do
        result = use_case.call(user_id: -1, title: "Test")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:not_found)
      end
    end

    context "with valid params" do
      it "creates a notification" do
        result = use_case.call(user_id: user.id, title: "Price Alert", body: "AAPL hit $200")

        expect(result).to be_success
        expect(result.value!).to be_a(Notification)
        expect(result.value!.title).to eq("Price Alert")
        expect(result.value!.read).to be false
      end

      it "publishes NotificationCreated event" do
        allow(EventBus).to receive(:publish)

        use_case.call(user_id: user.id, title: "Test")

        expect(EventBus).to have_received(:publish).with(
          an_instance_of(Notifications::NotificationCreated)
        )
      end
    end

    context "with alert_triggered type and notifiable" do
      let(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL") }

      it "sets notification_type and notifiable" do
        result = use_case.call(
          user_id: user.id,
          title: "Alert",
          notification_type: :alert_triggered,
          notifiable: rule
        )

        expect(result.value!.notification_type).to eq("alert_triggered")
        expect(result.value!.notifiable).to eq(rule)
      end
    end
  end
end
