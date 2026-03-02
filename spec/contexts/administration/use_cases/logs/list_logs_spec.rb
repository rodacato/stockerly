require "rails_helper"

RSpec.describe Administration::Logs::ListLogs do
  let!(:success_log) { create(:system_log, severity: :success, task_name: "FX Rate Update", module_name: "Finance") }
  let!(:error_log) { create(:system_log, severity: :error, task_name: "Price Sync", module_name: "Market") }
  let!(:warning_log) { create(:system_log, severity: :warning, task_name: "Inventory Audit", module_name: "Finance") }

  describe "#call" do
    it "returns all logs with pagination" do
      result = described_class.call(params: {})
      expect(result).to be_success
      data = result.value!
      expect(data[:logs].size).to eq(3)
      expect(data[:pagy]).to be_a(Pagy)
    end

    it "filters by severity" do
      result = described_class.call(params: { severity: "error" })
      data = result.value!
      expect(data[:logs]).to include(error_log)
      expect(data[:logs]).not_to include(success_log)
    end

    it "filters by module" do
      result = described_class.call(params: { module_name: "Finance" })
      data = result.value!
      expect(data[:logs]).to include(success_log, warning_log)
      expect(data[:logs]).not_to include(error_log)
    end

    it "searches by task name" do
      result = described_class.call(params: { search: "Price" })
      data = result.value!
      expect(data[:logs]).to include(error_log)
      expect(data[:logs]).not_to include(success_log)
    end
  end
end
