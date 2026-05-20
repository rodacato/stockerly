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
        "alert_triggered" => 0, "earnings_reminder" => 1, "system" => 2, "maturity_reminder" => 3
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

    it ".recent orders by created_at desc" do
      older = create(:notification, user: user, created_at: 2.days.ago)
      newer = create(:notification, user: user, created_at: 1.hour.ago)
      expect(Notification.recent.to_a).to eq([ newer, older ])
    end

    it ".read_only returns only read notifications" do
      r = create(:notification, user: user, read: true)
      create(:notification, user: user, read: false)
      expect(Notification.read_only).to contain_exactly(r)
    end

    it ".by_tipo('alertas') includes triggers + earnings + maturity reminders" do
      a = create(:notification, user: user, notification_type: :alert_triggered)
      e = create(:notification, user: user, notification_type: :earnings_reminder)
      m = create(:notification, user: user, notification_type: :maturity_reminder)
      create(:notification, user: user, notification_type: :system)
      expect(Notification.by_tipo("alertas")).to contain_exactly(a, e, m)
    end

    it ".by_tipo('sistema') returns only system notifications" do
      s = create(:notification, user: user, notification_type: :system)
      create(:notification, user: user, notification_type: :alert_triggered)
      expect(Notification.by_tipo("sistema")).to contain_exactly(s)
    end

    it ".by_estado('no_leidas') returns only unread" do
      u = create(:notification, user: user, read: false)
      create(:notification, user: user, read: true)
      expect(Notification.by_estado("no_leidas")).to contain_exactly(u)
    end
  end

  describe "#mark_as_read!" do
    it "marks notification as read and stamps read_at" do
      notification = create(:notification, read: false)
      notification.mark_as_read!
      notification.reload
      expect(notification.read).to be true
      expect(notification.read_at).to be_present
    end
  end

  describe "#kind" do
    it "returns 'alerta' for alert_triggered + reminder types" do
      %i[alert_triggered earnings_reminder maturity_reminder].each do |type|
        expect(build(:notification, notification_type: type).kind).to eq("alerta")
      end
    end

    it "returns 'sistema' for system type" do
      expect(build(:notification, notification_type: :system).kind).to eq("sistema")
    end
  end

  describe "associations" do
    it "allows nil notifiable (polymorphic optional)" do
      notification = build(:notification, notifiable: nil)
      expect(notification).to be_valid
    end
  end
end
