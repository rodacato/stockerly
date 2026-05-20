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
  end
end
