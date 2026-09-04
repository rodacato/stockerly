require "rails_helper"

RSpec.describe Notifications::UseCases::CreateNotification do
  subject(:use_case) { described_class.new }

  let(:user) { create(:user) }

  describe "#call" do
    context "when user does not exist" do
      it "notifies nobody" do
        expect { expect(use_case.call(user_id: -1, title: "Test")).to be_nil }
          .not_to change(Notification, :count)
      end
    end

    context "with valid params" do
      it "creates a notification" do
        result = use_case.call(user_id: user.id, title: "Price Alert", body: "AAPL hit $200")

        expect(result).to be_a(Notification)
        expect(result.title).to eq("Price Alert")
        expect(result.read).to be false
      end

      it "publishes NotificationCreated event" do
        allow(EventBus).to receive(:publish)

        use_case.call(user_id: user.id, title: "Test")

        expect(EventBus).to have_received(:publish).with(
          an_instance_of(Notifications::Events::NotificationCreated)
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

        expect(result.notification_type).to eq("alert_triggered")
        expect(result.notifiable).to eq(rule)
      end
    end
  end
end
