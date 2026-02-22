require "rails_helper"

RSpec.describe AlertEvent, type: :model do
  subject(:event) { build(:alert_event) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires asset_symbol" do
      event.asset_symbol = nil
      expect(event).not_to be_valid
    end

    it "requires message" do
      event.message = nil
      expect(event).not_to be_valid
    end

    it "requires triggered_at" do
      event.triggered_at = nil
      expect(event).not_to be_valid
    end
  end

  describe "enums" do
    it "defines event_status enum" do
      expect(AlertEvent.event_statuses).to eq("triggered" => 0, "settled" => 1)
    end
  end

  describe "scopes" do
    it ".recent returns last 10 ordered by triggered_at desc" do
      user = create(:user)
      old = create(:alert_event, user: user, triggered_at: 2.days.ago)
      recent = create(:alert_event, user: user, triggered_at: 1.hour.ago)
      expect(AlertEvent.recent.first).to eq(recent)
    end
  end
end
