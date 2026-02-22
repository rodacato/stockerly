require "rails_helper"

RSpec.describe Admin::Logs::ExportCsv do
  describe ".call" do
    let(:admin) { create(:user, :admin) }

    before do
      create(:system_log, task_name: "Price Sync: AAPL", module_name: "sync", severity: :success, duration_seconds: 1.2)
      create(:system_log, task_name: "FX Rate Refresh", module_name: "sync", severity: :error, error_message: "Timeout")
    end

    it "returns CSV string with headers" do
      result = described_class.call(admin: admin)

      expect(result).to be_success
      csv = result.value!
      expect(csv).to include("ID,Severity,Task,Module,Duration,Timestamp,Error")
    end

    it "includes log data in CSV rows" do
      result = described_class.call(admin: admin)
      csv = result.value!

      expect(csv).to include("Price Sync: AAPL")
      expect(csv).to include("FX Rate Refresh")
      expect(csv).to include("Timeout")
    end

    it "applies filter params" do
      result = described_class.call(admin: admin, params: { severity: "error" })
      csv = result.value!

      expect(csv).to include("FX Rate Refresh")
      expect(csv).not_to include("Price Sync: AAPL")
    end

    it "publishes CsvExported event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(CsvExported))

      described_class.call(admin: admin)
    end
  end
end
