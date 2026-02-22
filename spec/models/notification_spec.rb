require "rails_helper"

RSpec.describe Notification, type: :model do
  subject(:notification) { build(:notification) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires title" do
      notification.title = nil
      expect(notification).not_to be_valid
    end
  end

  describe "enums" do
    it "defines notification_type enum" do
      expect(Notification.notification_types).to eq(
        "alert_triggered" => 0, "earnings_reminder" => 1, "system" => 2
      )
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    it ".unread returns only unread notifications" do
      unread = create(:notification, user: user, read: false)
      read_notif = create(:notification, user: user, read: true)
      expect(Notification.unread).to contain_exactly(unread)
    end

    it ".recent returns last 20 ordered by created_at desc" do
      25.times { create(:notification, user: user) }
      expect(Notification.recent.count).to eq(20)
    end
  end

  describe "#mark_as_read!" do
    it "marks notification as read" do
      notification = create(:notification, read: false)
      notification.mark_as_read!
      expect(notification.reload.read).to be true
    end
  end

  describe "associations" do
    it "allows nil notifiable (polymorphic optional)" do
      notification = build(:notification, notifiable: nil)
      expect(notification).to be_valid
    end
  end
end
