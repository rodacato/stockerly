require "rails_helper"

RSpec.describe ResolveBmvSymbolsJob, type: :job do
  let(:provider) { MarketData::Gateways::DataBursatilGateway::PROVIDER }

  def stub_serie(name, status:, body: "{}")
    stub_request(:get, "https://api.databursatil.com/v2/cotizaciones")
      .with(query: hash_including("emisora_serie" => name))
      .to_return(status: status, headers: { "Content-Type" => "application/json" }, body: body)
  end

  context "with a key" do
    before { create(:integration, provider_name: provider, api_key_encrypted: "test_token") }

    it "maps what the provider confirms and logs a success" do
      asset = create(:asset, :mexican, symbol: "GFNORTEO.MX", provider_symbols: {})
      quote = { "bmv" => { "u" => "150", "v" => "1", "f" => Time.current.iso8601, "pp" => "0" } }
      stub_serie("GFNORTEO", status: 200, body: { "GFNORTEO" => quote }.to_json)

      described_class.perform_now

      expect(asset.reload.provider_symbols[provider]).to eq("GFNORTEO")
      expect(SystemLog.last).to have_attributes(task_name: described_class::TASK, severity: "success")
    end

    it "logs a warning naming what it could not confirm, and maps nothing" do
      asset = create(:asset, :mexican, symbol: "UNKNOWN.MX", provider_symbols: {})
      stub_serie("UNKNOWN", status: 400)
      stub_serie("UNKNOWN*", status: 400)

      described_class.perform_now

      expect(asset.reload.provider_symbols).to be_empty
      expect(SystemLog.last).to have_attributes(severity: "warning")
      expect(SystemLog.last.error_message).to include("UNKNOWN.MX")
    end

    it "asks the provider nothing the second time" do
      create(:asset, :mexican, symbol: "WALMEX.MX", provider_symbols: { provider => "WALMEX*" })

      described_class.perform_now

      expect(a_request(:get, %r{api\.databursatil\.com})).not_to have_been_made
      expect(SystemLog.last).to have_attributes(severity: "success")
    end
  end

  it "says so when the provider has no key, instead of failing the job" do
    create(:asset, :mexican, symbol: "WALMEX.MX", provider_symbols: {})

    expect { described_class.perform_now }.not_to raise_error

    expect(SystemLog.last).to have_attributes(severity: "error")
    expect(SystemLog.last.error_message).to include("API key")
  end
end
