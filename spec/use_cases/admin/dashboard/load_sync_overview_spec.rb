require "rails_helper"

RSpec.describe Admin::Dashboard::LoadSyncOverview do
  describe ".call" do
    it "returns Success with sync overview data" do
      result = described_class.call

      expect(result).to be_success
      overview = result.value!
      expect(overview).to have_key(:sync_counts)
      expect(overview).to have_key(:integrations)
      expect(overview).to have_key(:status_counts)
      expect(overview).to have_key(:stale_count)
      expect(overview).to have_key(:recent_errors)
    end

    it "counts sync logs by severity" do
      create(:system_log, module_name: "sync", severity: :success, task_name: "sync_asset")
      create(:system_log, module_name: "sync", severity: :success, task_name: "sync_asset")
      create(:system_log, module_name: "sync", severity: :error, task_name: "sync_asset")

      result = described_class.call
      counts = result.value![:sync_counts]

      expect(counts["success"]).to eq(2)
      expect(counts["error"]).to eq(1)
    end

    it "excludes non-sync logs from sync_counts" do
      create(:system_log, module_name: "auth", severity: :success, task_name: "login")
      create(:system_log, module_name: "sync", severity: :success, task_name: "sync_asset")

      result = described_class.call
      counts = result.value![:sync_counts]

      expect(counts["success"]).to eq(1)
    end

    it "includes integrations" do
      create(:integration, provider_name: "Polygon.io", provider_type: "Stocks & Forex")

      result = described_class.call

      expect(result.value![:integrations].count).to eq(1)
    end

    it "groups assets by sync status" do
      create(:asset, sync_status: :active)
      create(:asset, sync_status: :active)
      create(:asset, sync_status: :disabled)

      result = described_class.call
      counts = result.value![:status_counts]

      expect(counts["active"]).to eq(2)
      expect(counts["disabled"]).to eq(1)
    end

    it "counts stale assets" do
      create(:asset, sync_status: :active, price_updated_at: 1.hour.ago)
      create(:asset, sync_status: :active, price_updated_at: 1.minute.ago)

      result = described_class.call

      expect(result.value![:stale_count]).to eq(1)
    end

    it "returns recent sync errors limited to 5" do
      6.times do |i|
        create(:system_log, module_name: "sync", severity: :error,
               task_name: "sync_#{i}", error_message: "Failed #{i}")
      end

      result = described_class.call

      expect(result.value![:recent_errors].count).to eq(5)
    end
  end
end
