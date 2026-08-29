require "rails_helper"

RSpec.describe Notifications::Handlers::SendPushNotification do
  let(:user) { create(:user) }
  let!(:subscription) { create(:push_subscription, user: user) }
  let(:notification) { create(:notification, user: user, notification_type: :alert_triggered, title: "AAPL cruzó 180") }

  def event_for(record)
    Notifications::Events::NotificationCreated.new(
      notification_id: record.id, user_id: record.user_id, title: record.title
    )
  end

  before { create(:alert_preference, user: user, push: push_enabled) }

  context "when the user asked for push" do
    let(:push_enabled) { true }

    it "delivers to every install, carrying the unread count for the badge" do
      create(:notification, user: user, read: false)

      expect(Notifications::Domain::WebPushDelivery).to receive(:call)
        .with(hash_including(subscription: subscription, title: "AAPL cruzó 180", badge_count: 2))

      described_class.call(event_for(notification))
    end

    # Earnings and maturity notices have a date, not an urgency — same line the
    # urgent email draws. Pushing them would make the channel unusable.
    it "stays quiet for a notification that is not a fired rule" do
      reminder = create(:notification, user: user, notification_type: :earnings_reminder)

      expect(Notifications::Domain::WebPushDelivery).not_to receive(:call)

      described_class.call(event_for(reminder))
    end
  end

  context "when the user did not ask for push" do
    let(:push_enabled) { false }

    it "delivers nothing even though an install is subscribed" do
      expect(Notifications::Domain::WebPushDelivery).not_to receive(:call)

      described_class.call(event_for(notification))
    end
  end
end
