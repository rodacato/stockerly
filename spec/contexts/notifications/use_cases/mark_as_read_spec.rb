require "rails_helper"

RSpec.describe Notifications::UseCases::MarkAsRead do
  let(:user) { create(:user) }

  describe "#call" do
    it "marks a specific notification as read" do
      notif = create(:notification, user: user, read: false)
      result = described_class.call(user: user, notification_id: notif.id)
      expect(result).to be_success
      expect(notif.reload.read).to be true
    end

    it "returns failure when notification not found" do
      result = described_class.call(user: user, notification_id: 999)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it "marks all notifications as read when no id given" do
      create_list(:notification, 3, user: user, read: false)
      result = described_class.call(user: user)
      expect(result).to be_success
      expect(user.notifications.unread.count).to eq(0)
    end
  end
end
