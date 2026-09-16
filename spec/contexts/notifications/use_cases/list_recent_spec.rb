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
      expect(data[:counts]).to eq(alertas: 1, reportes: 1, cetes: 0, all: 3, unread: 1, read: 2)
    end

    it "returns zero unread count when all notifications are read" do
      create(:notification, user: user, read: true)
      expect(described_class.call(user: user)[:counts][:unread]).to eq(0)
    end

    it "gives each bucket only its own type" do
      create(:notification, user: user, notification_type: :alert_triggered)
      create(:notification, user: user, notification_type: :earnings_reminder)
      create(:notification, user: user, notification_type: :maturity_reminder)
      create(:notification, user: user, notification_type: :system)

      expect(described_class.call(user: user, tipo: "alertas")[:notifications].size).to eq(1)
      expect(described_class.call(user: user, tipo: "reportes")[:notifications].size).to eq(1)
      expect(described_class.call(user: user, tipo: "cetes")[:notifications].size).to eq(1)
    end

    it "leaves system notices reachable through the unfiltered list" do
      create(:notification, user: user, notification_type: :system)

      # No chip of their own — the artboard draws four buckets and system is
      # not one of them — so "todos" is the only place they appear.
      expect(described_class.call(user: user)[:notifications].size).to eq(1)
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
      expect(data[:counts][:alertas]).to eq(1)
      # A system notice has no chip, so it shows up in `all` and nowhere else.
      expect(data[:counts][:reportes]).to eq(0)
    end
  end
end
