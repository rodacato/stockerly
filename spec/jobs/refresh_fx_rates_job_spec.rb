require "rails_helper"

RSpec.describe RefreshFxRatesJob, type: :job do
  describe "#perform" do
    context "when API returns valid data" do
      before { stub_fx_rates }

      it "creates FxRate records" do
        expect {
          described_class.perform_now
        }.to change(FxRate, :count).by(3)
      end

      it "creates a success SystemLog entry" do
        expect {
          described_class.perform_now
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to eq("FX Rate Refresh")
      end
    end

    context "when API returns an error" do
      before { stub_fx_rates_server_error }

      it "creates an error SystemLog entry" do
        described_class.perform_now

        log = SystemLog.last
        expect(log.severity).to eq("error")
        expect(log.task_name).to eq("FX Rate Refresh")
      end
    end
  end
end
