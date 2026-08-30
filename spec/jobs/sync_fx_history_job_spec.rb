require "rails_helper"

RSpec.describe SyncFxHistoryJob do
  let(:series) { MarketData::Gateways::BanxicoGateway::FIX_SERIES }

  before do
    allow(MarketData::Gateways::BanxicoGateway).to receive(:new).and_return(
      MarketData::Gateways::BanxicoGateway.new(api_key: "test_token")
    )
  end

  def banxico_response(datos)
    { bmx: { series: [ { idSerie: series, datos: datos } ] } }.to_json
  end

  it "logs what it stored instead of raising" do
    stub_request(:get, %r{series/#{series}/datos/}).to_return(
      status: 200,
      body: banxico_response([ { "fecha" => "11/05/2026", "dato" => "17.0100" } ]),
      headers: { "Content-Type" => "application/json" }
    )

    expect { described_class.perform_now }.to change(SystemLog, :count).by(1)

    log = SystemLog.last
    expect(log.task_name).to eq("FX History Sync")
    expect(log).to be_success
    expect(log.error_message).to eq("Stored 1 FIX rate(s)")
  end

  it "logs the failure instead of raising when Banxico is down" do
    stub_request(:get, %r{series/#{series}/datos/}).to_return(status: 500)

    expect { described_class.perform_now }.not_to raise_error

    log = SystemLog.last
    expect(log.task_name).to eq("FX History Sync")
    expect(log).to be_error
  end
end
