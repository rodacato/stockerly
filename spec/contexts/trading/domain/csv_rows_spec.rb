require "rails_helper"

RSpec.describe Trading::Domain::CsvRows do
  let(:header) { "asset_symbol,side,shares,price_per_share,currency,executed_at" }

  it "returns one hash per row, keyed by symbol" do
    rows = described_class.call(text: "#{header}\nVT,buy,2.0,100.0,USD,2025-12-08")

    expect(rows).to eq([ { asset_symbol: "VT", side: "buy", shares: "2.0", price_per_share: "100.0", currency: "USD", executed_at: "2025-12-08" } ])
  end

  it "drops the broker's own provenance columns instead of rejecting them" do
    rows = described_class.call(text: "#{header},cusip,settle_date,source_file\nVT,buy,2.0,100.0,USD,2025-12-08,922042742,2025-12-09,a.pdf")

    expect(rows.first.keys).to contain_exactly(:asset_symbol, :side, :shares, :price_per_share, :currency, :executed_at)
  end

  it "keeps the optional columns the importer does use" do
    rows = described_class.call(text: "#{header},fee,external_id,net_amount\nVT,buy,2.0,100.0,USD,2025-12-08,0,order-1,-200.00")

    expect(rows.first).to include(fee: "0", external_id: "order-1", net_amount: "-200.00")
  end

  it "names the required columns that are missing" do
    expect {
      described_class.call(text: "asset_symbol,side\nVT,buy")
    }.to raise_error(described_class::MissingHeader, /shares, price_per_share, currency, executed_at/)
  end

  # The contract requires a currency on every row, so a file without the column
  # can never import. Saying so once beats saying it once per row.
  it "names currency as missing rather than failing every row on it later" do
    expect {
      described_class.call(text: "asset_symbol,side,shares,price_per_share,executed_at\nVT,buy,2.0,100.0,2025-12-08")
    }.to raise_error(described_class::MissingHeader, "Faltan columnas: currency")
  end

  it "raises rather than returning garbage for malformed CSV" do
    expect {
      described_class.call(text: "#{header}\nVT,\"buy,2.0")
    }.to raise_error(described_class::MissingHeader)
  end

  it "tells an empty file what it is missing rather than returning nothing" do
    expect {
      described_class.call(text: "")
    }.to raise_error(described_class::MissingHeader, /asset_symbol/)
  end
end
