require "rails_helper"

RSpec.describe Notifications::Handlers::BroadcastNotification do
  describe ".call" do
    let(:user) { create(:user) }
    let!(:notification) { create(:notification, user: user, title: "Test", read: false) }

    before do
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      allow(Turbo::StreamsChannel).to receive(:broadcast_prepend_to)
    end

    it "broadcasts badge update" do
      described_class.call(notification_id: notification.id, user_id: user.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "notifications_#{user.id}",
        target: "notification_badge",
        partial: "shared/notification_badge",
        locals: { unread_count: 1 }
      )
    end

    it "broadcasts notification prepend" do
      described_class.call(notification_id: notification.id, user_id: user.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_prepend_to).with(
        "notifications_#{user.id}",
        target: "notifications_list",
        partial: "shared/notification_item",
        locals: { notification: notification }
      )
    end

    it "does nothing when notification not found" do
      described_class.call(notification_id: -1, user_id: user.id)

      expect(Turbo::StreamsChannel).not_to have_received(:broadcast_replace_to)
    end
  end
end
