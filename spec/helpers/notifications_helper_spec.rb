require "rails_helper"

RSpec.describe NotificationsHelper, type: :helper do
  describe "#notification_icon" do
    it "returns bolt for alert_triggered" do
      notification = build(:notification, notification_type: :alert_triggered)
      expect(helper.notification_icon(notification)).to eq("bolt")
    end

    it "returns calendar_today for earnings_reminder" do
      notification = build(:notification, notification_type: :earnings_reminder)
      expect(helper.notification_icon(notification)).to eq("calendar_today")
    end

    it "returns settings for system" do
      notification = build(:notification, notification_type: :system)
      expect(helper.notification_icon(notification)).to eq("settings")
    end

    it "returns notifications for unrecognized type" do
      notification = build(:notification, notification_type: :system)
      allow(notification).to receive(:notification_type).and_return("other")
      expect(helper.notification_icon(notification)).to eq("notifications")
    end
  end

  describe "#notification_icon_style" do
    it "returns muted style for read notifications" do
      notification = build(:notification, read: true)
      expect(helper.notification_icon_style(notification)).to include("text-slate-400")
    end

    it "returns amber style for unread alert_triggered" do
      notification = build(:notification, notification_type: :alert_triggered, read: false)
      expect(helper.notification_icon_style(notification)).to include("bg-amber-100")
    end

    it "returns blue style for unread earnings_reminder" do
      notification = build(:notification, notification_type: :earnings_reminder, read: false)
      expect(helper.notification_icon_style(notification)).to include("bg-blue-100")
    end

    it "returns slate style for unread system notification" do
      notification = build(:notification, notification_type: :system, read: false)
      expect(helper.notification_icon_style(notification)).to include("text-slate-600")
    end

    it "returns default style for unread unrecognized type" do
      notification = build(:notification, notification_type: :system, read: false)
      allow(notification).to receive(:notification_type).and_return("other")
      expect(helper.notification_icon_style(notification)).to include("bg-slate-100")
    end
  end
end
