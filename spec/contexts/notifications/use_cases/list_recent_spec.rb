require "rails_helper"

RSpec.describe Notifications::UseCases::ListRecent do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns the notifications relation with chip counts" do
      create(:notification, user: user, notification_type: :alert_triggered,   read: false)
      create(:notification, user: user, notification_type: :system,            read: true)
      create(:notification, user: user, notification_type: :earnings_reminder, read: true)

      data = described_class.call(user: user)

      expect(data[:notifications].size).to eq(3)
      expect(data[:tipo]).to eq("todos")
      expect(data[:estado]).to eq("todos")
      expect(data[:shown_count]).to eq(3)
      expect(data[:counts]).to eq(all: 3, alerts: 2, system: 1, unread: 1, read: 2)
    end

    it "returns zero unread count when all notifications are read" do
      create(:notification, user: user, read: true)
      expect(described_class.call(user: user)[:counts][:unread]).to eq(0)
    end

    it "filters by tipo=alertas (alert_triggered + earnings + maturity reminders)" do
      create(:notification, user: user, notification_type: :alert_triggered)
      create(:notification, user: user, notification_type: :earnings_reminder)
      create(:notification, user: user, notification_type: :maturity_reminder)
      create(:notification, user: user, notification_type: :system)

      data = described_class.call(user: user, tipo: "alertas")

      expect(data[:notifications].size).to eq(3)
      expect(data[:shown_count]).to eq(3)
    end

    it "filters by tipo=sistema" do
      create(:notification, user: user, notification_type: :alert_triggered)
      create(:notification, user: user, notification_type: :system)

      data = described_class.call(user: user, tipo: "sistema")
      expect(data[:notifications].size).to eq(1)
      expect(data[:notifications].first.notification_type).to eq("system")
    end

    it "filters by estado=no_leidas" do
      create(:notification, user: user, read: false)
      create(:notification, user: user, read: true)

      data = described_class.call(user: user, estado: "no_leidas")
      expect(data[:shown_count]).to eq(1)
    end

    it "filters by estado=leidas" do
      create(:notification, user: user, read: false)
      create(:notification, user: user, read: true)

      data = described_class.call(user: user, estado: "leidas")
      expect(data[:shown_count]).to eq(1)
    end

    it "always returns counts over the full unfiltered scope" do
      create(:notification, user: user, notification_type: :alert_triggered, read: false)
      create(:notification, user: user, notification_type: :system,          read: true)

      data = described_class.call(user: user, tipo: "alertas")
      expect(data[:counts][:all]).to eq(2)
      expect(data[:counts][:alerts]).to eq(1)
      expect(data[:counts][:system]).to eq(1)
    end

    describe "N+1 guard — notifiable + asset preloading is bounded by type, not by row" do
      it "issues a constant number of queries regardless of how many notifications carry asset-bearing notifiables" do
        # 5 EarningsEvent notifications + 5 Position notifications + 5 AlertRule
        # notifications. Without the two-step polymorphic preload, each row that
        # reads `notifiable.asset.symbol` (10 rows) would fire its own SELECT.
        # The preloader caps that at ONE query per asset-owning klass.
        portfolio = create(:portfolio, user: user)

        5.times do |i|
          asset = create(:asset, :stock, symbol: "STK#{i}")
          event = create(:earnings_event, asset: asset)
          create(:notification, user: user, notifiable: event, notification_type: :earnings_reminder)
        end
        5.times do |i|
          asset    = create(:asset, :fixed_income, symbol: "CET#{i}")
          position = create(:position, portfolio: portfolio, asset: asset, maturity_date: 3.days.from_now)
          create(:notification, user: user, notifiable: position, notification_type: :maturity_reminder)
        end
        5.times do |i|
          rule = create(:alert_rule, user: user, asset_symbol: "ALR#{i}")
          create(:notification, user: user, notifiable: rule, notification_type: :alert_triggered)
        end

        # The exact query budget breaks down roughly as:
        # - 4 counts (notification_type group, unread, plus the all/read math)
        # - 1 main filtered notifications select
        # - 1 polymorphic notifiable preload per concrete klass (3 types)
        # - 1 asset preload per asset-owning klass (2 types)
        # - 1 to_a/size materialization for filtered + 1 per row in test
        # Cap is generous to absorb factory churn but tight enough that a
        # regression into per-row `n.notifiable.asset` loops would blow past it.
        expect {
          data = described_class.call(user: user)
          # Force the inbox-row code path the helper walks per row.
          data[:notifications].each { |n| n.notifiable&.is_a?(EarningsEvent) ? n.notifiable.asset&.symbol : nil }
          data[:notifications].each { |n| n.notifiable&.is_a?(Position) ? n.notifiable.asset&.symbol : nil }
        }.to make_queries(at_most: 15)
      end
    end
  end
end
