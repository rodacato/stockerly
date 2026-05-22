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
    # Anchor timestamps at noon-of-day so bucket assignment is deterministic
    # regardless of when the suite runs. Using relative offsets (`2.hours.ago`,
    # `1.day.ago`) made the spec flake when CI hit it near midnight UTC —
    # `2.hours.ago` could land in `yesterday`, breaking the count.
    let(:noon_today)      { Date.current.beginning_of_day + 12.hours }
    let(:noon_yesterday)  { noon_today - 1.day }
    let(:noon_5_days_ago) { noon_today - 5.days }

    it "buckets into Hoy / Ayer / Más temprano in display order" do
      today_n     = create(:notification, user: user, created_at: noon_today)
      yesterday_n = create(:notification, user: user, created_at: noon_yesterday)
      earlier_n   = create(:notification, user: user, created_at: noon_5_days_ago)

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
      today_n = create(:notification, user: user, created_at: noon_today)
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

  describe "#notifiable_asset_symbol" do
    let(:user) { create(:user) }

    it "returns the symbol carried by an AlertRule (no Asset lookup)" do
      rule = create(:alert_rule, user: user, asset_symbol: "AAPL")
      n    = create(:notification, user: user, notifiable: rule)

      expect(helper.notifiable_asset_symbol(n)).to eq("AAPL")
    end

    it "returns the symbol from an EarningsEvent's preloaded asset" do
      asset = create(:asset, :stock, symbol: "NVDA")
      event = create(:earnings_event, asset: asset)
      n     = create(:notification, user: user, notifiable: event)

      expect(helper.notifiable_asset_symbol(n)).to eq("NVDA")
    end

    it "returns nil when there is no notifiable" do
      n = create(:notification, user: user, notifiable: nil)
      expect(helper.notifiable_asset_symbol(n)).to be_nil
    end
  end
end
