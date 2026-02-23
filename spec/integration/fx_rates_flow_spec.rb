require "rails_helper"

RSpec.describe "FX Rates Flow (E2E)", type: :model do
  before { stub_fx_rates }

  it "refreshes FX rates → creates records → logs success" do
    expect {
      RefreshFxRatesJob.perform_now
    }.to change(FxRate, :count).by(3)
      .and change(SystemLog, :count).by(1)

    log = SystemLog.last
    expect(log.task_name).to eq("FX Rate Refresh")
    expect(log.severity).to eq("success")

    # Verify FxRate records
    eur_rate = FxRate.find_by(base_currency: "USD", quote_currency: "EUR")
    expect(eur_rate).to be_present
    expect(eur_rate.rate).to be > 0
  end
end
