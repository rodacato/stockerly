require "rails_helper"

RSpec.describe DataFreshness do
  describe ".newest_data_age_seconds" do
    it "returns the age in seconds of the most recently synced source" do
      create(:asset, sync_status: :active, price_updated_at: 5.minutes.ago)
      SystemLog.create!(task_name: "FX Rates Sync", module_name: "sync", severity: :success,
                        duration_seconds: 0, created_at: 3.hours.ago)

      age = described_class.newest_data_age_seconds

      expect(age).to be_within(2).of(5.minutes.to_i)
    end

    it "returns nil when nothing has synced yet" do
      expect(described_class.newest_data_age_seconds).to be_nil
    end

    it "ignores assets that are not actively synced" do
      create(:asset, sync_status: :disabled, price_updated_at: 1.minute.ago)

      expect(described_class.newest_data_age_seconds).to be_nil
    end
  end

  describe ".checks" do
    it "flags a source as degraded past its ok threshold" do
      create(:asset, sync_status: :active, price_updated_at: 30.minutes.ago)

      expect(described_class.checks[:prices]).to eq("degraded")
    end

    it "flags a source as critical past its degraded threshold" do
      create(:asset, sync_status: :active, price_updated_at: 2.hours.ago)

      expect(described_class.checks[:prices]).to eq("critical")
    end

    it "reports ok when a source has no data" do
      expect(described_class.checks[:fx_rates]).to eq("ok")
    end
  end

  describe ".overall_status" do
    it "is critical when any check is critical" do
      checks = { prices: "ok", indices: "critical", fx_rates: "degraded" }

      expect(described_class.overall_status(checks)).to eq("critical")
    end

    it "is degraded when a check is degraded and none critical" do
      checks = { prices: "ok", indices: "degraded", fx_rates: "ok" }

      expect(described_class.overall_status(checks)).to eq("degraded")
    end

    it "is ok when all checks pass" do
      checks = { prices: "ok", indices: "ok", fx_rates: "ok" }

      expect(described_class.overall_status(checks)).to eq("ok")
    end
  end
end
