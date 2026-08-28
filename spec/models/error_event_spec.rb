require "rails_helper"

RSpec.describe ErrorEvent, type: :model do
  describe "validations" do
    it "rejects a second row with the same fingerprint" do
      create(:error_event, fingerprint: "same")

      duplicate = build(:error_event, fingerprint: "same")

      expect(duplicate).not_to be_valid
    end

    it "rejects a source outside the known set" do
      expect(build(:error_event, source: "cron")).not_to be_valid
    end
  end

  describe ".purge_stale!" do
    it "deletes rows last seen before the retention window and keeps the rest" do
      stale = create(:error_event, :stale)
      fresh = create(:error_event, last_seen_at: 1.day.ago)

      described_class.purge_stale!

      expect(described_class.pluck(:id)).to contain_exactly(fresh.id)
      expect { stale.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "keeps a row sitting exactly on the boundary" do
      now = Time.current
      boundary = create(:error_event, last_seen_at: now - ErrorEvent::RETENTION)

      described_class.purge_stale!(now)

      expect(boundary.reload).to be_present
    end
  end

  describe ".recent" do
    it "orders by last seen, newest first" do
      old = create(:error_event, last_seen_at: 2.days.ago)
      new = create(:error_event, last_seen_at: 1.hour.ago)

      expect(described_class.recent.pluck(:id)).to eq([ new.id, old.id ])
    end
  end
end
