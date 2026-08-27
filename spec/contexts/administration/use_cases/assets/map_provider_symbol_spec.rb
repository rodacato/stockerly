require "rails_helper"

RSpec.describe Administration::UseCases::Assets::MapProviderSymbol do
  let(:asset) { create(:asset, :mexican, symbol: "WALMEX.MX", provider_symbols: {}) }

  before { create(:integration, provider_name: "DataBursatil", api_key_encrypted: "test_token") }

  def stub_serie(name, body)
    stub_request(:get, "https://api.databursatil.com/v2/cotizaciones")
      .with(query: hash_including("emisora_serie" => name))
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json)
  end

  def stub_rejected(name)
    stub_request(:get, "https://api.databursatil.com/v2/cotizaciones")
      .with(query: hash_including("emisora_serie" => name))
      .to_return(status: 400, body: "Emisoras y/o series desconocidas")
  end

  def bmv_quote(last)
    { "bmv" => { "u" => last.to_s, "v" => "1000", "f" => Time.current.iso8601, "c" => "0.5" } }
  end

  it "stores the name once the provider has answered to it" do
    stub_serie("WALMEX*", { "WALMEX*" => bmv_quote(47.81) })

    result = described_class.call(asset_id: asset.id, provider: "DataBursatil", symbol: "walmex*")

    expect(result).to be_success
    expect(asset.reload.provider_symbols["DataBursatil"]).to eq("WALMEX*")
  end

  # The whole point of probing first: a wrong mapping is worse than none,
  # because the sync then fails on a name the owner believes is right.
  it "writes nothing when the provider does not recognise the name" do
    stub_rejected("WALMEXX")

    result = described_class.call(asset_id: asset.id, provider: "DataBursatil", symbol: "WALMEXX")

    expect(result.failure.first).to eq(:unconfirmed)
    expect(asset.reload.provider_symbols).to be_empty
  end

  it "clears the marker the sync left, so the row stops saying it" do
    asset.update!(last_sync_error: SyncBulkBmvJob::UNNAMED)
    stub_serie("WALMEX*", { "WALMEX*" => bmv_quote(47.81) })

    described_class.call(asset_id: asset.id, provider: "DataBursatil", symbol: "WALMEX*")

    expect(asset.reload.last_sync_error).to be_nil
  end

  # The registry knows which sources serve this asset's market and type, so a
  # mapping cannot be recorded against one that was never in its chain.
  it "refuses a provider that does not serve this asset" do
    result = described_class.call(asset_id: asset.id, provider: "CoinGecko", symbol: "WALMEX*")

    expect(result.failure.first).to eq(:not_found)
    expect(asset.reload.provider_symbols).to be_empty
  end

  it "refuses an empty name without calling the provider" do
    result = described_class.call(asset_id: asset.id, provider: "DataBursatil", symbol: "   ")

    expect(result.failure.first).to eq(:validation)
    expect(a_request(:get, %r{api\.databursatil\.com})).not_to have_been_made
  end

  it "raises for an asset that does not exist, so the controller can 404" do
    expect { described_class.call(asset_id: 0, provider: "DataBursatil", symbol: "X") }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
