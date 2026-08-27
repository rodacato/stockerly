require "rails_helper"
require "rake"

RSpec.describe "data:resolve_bmv_symbols" do
  subject(:task) { Rake::Task["data:resolve_bmv_symbols"] }

  let(:provider) { MarketData::Gateways::DataBursatilGateway::PROVIDER }

  before do
    Rake.application.rake_require("tasks/bmv_symbols", [ Rails.root.join("lib").to_s ])
    Rake::Task.define_task(:environment)
    task.reenable
    create(:integration, provider_name: provider, api_key_encrypted: "test_token")
  end

  # DataBursatil addresses an instrument by issuer AND serie. Yahoo omits the
  # serie when it is `*`, which is the whole gap.
  def stub_serie(name, quote)
    stub_request(:get, "https://api.databursatil.com/v2/cotizaciones")
      .with(query: hash_including("emisora_serie" => name))
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: quote.to_json)
  end

  def stub_rejected(name)
    stub_request(:get, "https://api.databursatil.com/v2/cotizaciones")
      .with(query: hash_including("emisora_serie" => name))
      .to_return(status: 400, body: "emisora_serie invalida")
  end

  def bmv_quote(last)
    { "bmv" => { "u" => last.to_s, "v" => "1000", "f" => Time.current.iso8601, "pp" => "0.5" } }
  end

  # Measured against the real provider 2026-08-27: `WALMEX` is rejected 400 and
  # `WALMEX*` answers 200 keyed `"WALMEX*"` — with the star. That round-trip is
  # what `parse_quote` depends on, and it holds.
  it "stores the starred form for an issuer whose serie Yahoo omits" do
    asset = create(:asset, :mexican, symbol: "WALMEX.MX", provider_symbols: {})
    stub_rejected("WALMEX")
    stub_serie("WALMEX*", { "WALMEX*" => bmv_quote(47.81) })

    task.invoke

    expect(asset.reload.provider_symbols[provider]).to eq("WALMEX*")
  end

  it "leaves a ticker that already embeds its serie alone" do
    asset = create(:asset, :mexican, symbol: "GFNORTEO.MX", provider_symbols: {})
    stub_serie("GFNORTEO", { "GFNORTEO" => bmv_quote(150.0) })

    task.invoke

    expect(asset.reload.provider_symbols[provider]).to eq("GFNORTEO")
  end

  # The negative the issue asks for: a name that answers neither form is
  # reported, never guessed at. A wrong mapping fails the whole batch, which is
  # worse than no mapping at all.
  it "writes nothing for an issuer it could not confirm" do
    asset = create(:asset, :mexican, symbol: "UNKNOWN.MX", provider_symbols: {})
    stub_rejected("UNKNOWN")
    stub_rejected("UNKNOWN*")

    expect { task.invoke }.to output(/UNKNOWN\.MX/).to_stdout

    expect(asset.reload.provider_symbols).to be_empty
  end

  it "skips an asset that already carries a mapping, so re-running is free" do
    create(:asset, :mexican, symbol: "WALMEX.MX", provider_symbols: { provider => "WALMEX*" })

    task.invoke

    expect(a_request(:get, %r{api\.databursatil\.com})).not_to have_been_made
  end

  # CETES are Mexican and priced by Banxico, not by an exchange. Probing them
  # spends requests to learn nothing and lists them as unresolvable forever.
  it "never probes an asset type this provider does not serve" do
    asset = create(:asset, :fixed_income, symbol: "CETE28D", country: "MX",
                                          sync_status: :active, provider_symbols: {})

    task.invoke

    expect(a_request(:get, %r{api\.databursatil\.com})).not_to have_been_made
    expect(asset.reload.provider_symbols).to be_empty
  end

  it "never touches an asset outside Mexico" do
    asset = create(:asset, symbol: "AAPL", country: "US", provider_symbols: {})

    task.invoke

    expect(asset.reload.provider_symbols).to be_empty
  end
end
