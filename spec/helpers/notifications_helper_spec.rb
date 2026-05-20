require "rails_helper"

RSpec.describe NotificationsHelper, type: :helper do
  describe "#notification_icon" do
    {
      alert_triggered:   "notifications_active",
      earnings_reminder: "event",
      maturity_reminder: "event_available",
      system:            "info"
    }.each do |type, icon|
      it "returns #{icon} for #{type}" do
        notification = build(:notification, notification_type: type)
        expect(helper.notification_icon(notification)).to eq(icon)
      end
    end

    it "returns notifications for unrecognized type" do
      notification = build(:notification, notification_type: :system)
      allow(notification).to receive(:notification_type).and_return("other")
      expect(helper.notification_icon(notification)).to eq("notifications")
    end
  end

  describe "#notification_icon_style" do
    it "returns the emerald 'alerta' tile for alert + reminder types" do
      %i[alert_triggered earnings_reminder maturity_reminder].each do |type|
        n = build(:notification, notification_type: type)
        expect(helper.notification_icon_style(n)).to include("emerald")
      end
    end

    it "returns the primary 'sistema' tile for system notifications" do
      n = build(:notification, notification_type: :system)
      expect(helper.notification_icon_style(n)).to include("primary")
    end
  end

  describe "#notification_category_label" do
    it { expect(helper.notification_category_label(build(:notification, notification_type: :alert_triggered))).to eq("Alerta") }
    it { expect(helper.notification_category_label(build(:notification, notification_type: :system))).to eq("Sistema") }
  end

  describe "#group_notifications_by_date" do
    let(:user) { create(:user) }

    it "buckets into Hoy / Ayer / Más temprano in display order" do
      today_n     = create(:notification, user: user, created_at: 2.hours.ago)
      yesterday_n = create(:notification, user: user, created_at: 1.day.ago)
      earlier_n   = create(:notification, user: user, created_at: 5.days.ago)

      groups = helper.group_notifications_by_date([ today_n, yesterday_n, earlier_n ])

      expect(groups.length).to eq(3)
      expect(groups[0][0]).to start_with("Hoy")
      expect(groups[0][1]).to contain_exactly(today_n)
      expect(groups[1][0]).to start_with("Ayer")
      expect(groups[1][1]).to contain_exactly(yesterday_n)
      expect(groups[2][0]).to start_with("Más temprano")
      expect(groups[2][1]).to contain_exactly(earlier_n)
    end

    it "omits empty buckets" do
      today_n = create(:notification, user: user, created_at: 1.hour.ago)
      groups  = helper.group_notifications_by_date([ today_n ])
      expect(groups.length).to eq(1)
      expect(groups[0][0]).to start_with("Hoy")
    end
  end

  describe "#format_date_header" do
    it "formats with es-MX weekday + month abbreviations" do
      # Wednesday 2026-05-13
      expect(helper.format_date_header(Date.new(2026, 5, 13))).to eq("MIÉ 13 MAY 2026")
    end
  end
end
