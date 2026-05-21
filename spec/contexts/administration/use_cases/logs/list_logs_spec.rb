require "rails_helper"

RSpec.describe Administration::UseCases::Logs::ListLogs do
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

    it "also searches against error_message" do
      err = create(:system_log, :error, task_name: "Other Task", error_message: "yfinance HTTP 429")
      result = described_class.call(params: { search: "yfinance" })
      expect(result.value![:logs]).to include(err)
    end

    it "escapes LIKE meta-characters in the search input (regression #139)" do
      pct = create(:system_log, severity: :success, task_name: "Has Percent 50%", module_name: "Finance")
      # Without sanitize_sql_like, "%" would match anything — assert it now
      # only matches rows that actually contain the literal "%".
      result = described_class.call(params: { search: "50%" })
      logs = result.value![:logs]
      expect(logs).to include(pct)
      expect(logs).not_to include(success_log)
    end

    describe "date-range filter" do
      let!(:old_log) { create(:system_log, severity: :success, task_name: "Old", module_name: "sync", created_at: 40.days.ago) }

      it "defaults to the last 24 hours when no range is provided" do
        result = described_class.call(params: {})
        expect(result.value![:logs]).not_to include(old_log)
      end

      it "honors the 90d window when requested" do
        result = described_class.call(params: { range: "90d" })
        expect(result.value![:logs]).to include(old_log)
      end
    end
  end
end
