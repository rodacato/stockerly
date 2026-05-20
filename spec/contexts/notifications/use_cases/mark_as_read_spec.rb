require "rails_helper"

RSpec.describe Notifications::UseCases::MarkAsRead do
  let(:user) { create(:user) }

  describe "#call" do
    it "marks a specific notification as read and stamps read_at" do
      notif  = create(:notification, user: user, read: false)
      result = described_class.call(user: user, notification_id: notif.id)

      expect(result).to be_success
      notif.reload
      expect(notif.read).to be true
      expect(notif.read_at).to be_present
    end

    it "returns failure when notification not found" do
      result = described_class.call(user: user, notification_id: 999)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it "marks all unread notifications as read and stamps read_at" do
      create_list(:notification, 3, user: user, read: false)
      result = described_class.call(user: user)

      expect(result).to be_success
      expect(user.notifications.unread.count).to eq(0)
      expect(user.notifications.where.not(read_at: nil).count).to eq(3)
    end
  end
end
