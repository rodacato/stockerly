require "rails_helper"

RSpec.describe MarketData::Gateways::BanxicoGateway, "FIX rates" do
  let(:gateway) { described_class.new(api_key: "test-token") }
  let(:from) { Date.new(2026, 5, 11) }
  let(:to) { Date.new(2026, 5, 15) }
  let(:url) do
    "https://www.banxico.org.mx/SieAPIRest/service/v1/series/" \
      "#{described_class::FIX_SERIES}/datos/2026-05-11/2026-05-15"
  end

  def banxico_response(datos)
    { bmx: { series: [ { idSerie: described_class::FIX_SERIES, datos: datos } ] } }.to_json
  end

  # Deriving the URL from the constant cannot catch a revert to SF43718, which
  # would silently move every rate two banking days.
  it "asks for the settlement series, spelled out" do
    settlement = stub_request(
      :get,
      "https://www.banxico.org.mx/SieAPIRest/service/v1/series/SF60653/datos/2026-05-11/2026-05-15"
    ).to_return(
      status: 200,
      body: banxico_response([ { "fecha" => "11/05/2026", "dato" => "17.0100" } ]),
      headers: { "Content-Type" => "application/json" }
    )

    gateway.fetch_fx_fixes(from: from, to: to)

    expect(settlement).to have_been_requested
  end

  it "returns the published fixes oldest first" do
    stub_request(:get, url).to_return(
      status: 200,
      body: banxico_response([
        { "fecha" => "15/05/2026", "dato" => "17.2500" },
        { "fecha" => "11/05/2026", "dato" => "17.0100" }
      ]),
      headers: { "Content-Type" => "application/json" }
    )

    result = gateway.fetch_fx_fixes(from: from, to: to)

    expect(result).to be_success
    expect(result.value!).to eq([
      { date: Date.new(2026, 5, 11), rate: 17.01 },
      { date: Date.new(2026, 5, 15), rate: 17.25 }
    ])
  end

  # Banxico marks days it does not publish as "N/E" — a holiday, not a failure.
  it "skips non-publication days without failing the batch" do
    stub_request(:get, url).to_return(
      status: 200,
      body: banxico_response([
        { "fecha" => "11/05/2026", "dato" => "17.0100" },
        { "fecha" => "12/05/2026", "dato" => "N/E" }
      ]),
      headers: { "Content-Type" => "application/json" }
    )

    result = gateway.fetch_fx_fixes(from: from, to: to)

    expect(result.value!.map { |f| f[:date] }).to eq([ Date.new(2026, 5, 11) ])
  end

  it "reports a rate limit as its own failure so a retry can back off" do
    stub_request(:get, url).to_return(status: 429, body: "")

    expect(gateway.fetch_fx_fixes(from: from, to: to).failure.first).to eq(:rate_limited)
  end

  it "fails rather than returning an empty window as success" do
    stub_request(:get, url).to_return(
      status: 200,
      body: banxico_response([]),
      headers: { "Content-Type" => "application/json" }
    )

    expect(gateway.fetch_fx_fixes(from: from, to: to).failure.first).to eq(:not_found)
  end
end
