require "rails_helper"

RSpec.describe Alerts::Queries::SymbolListing do
  it "reports a symbol the catalogue lists" do
    create(:asset, symbol: "AAPL")

    expect(described_class.call(symbol: "aapl")).to eq(state: :listed)
  end

  it "reports a renamed symbol with the one that replaced it" do
    create(:asset, symbol: "META", former_symbols: [ "FB" ])

    expect(described_class.call(symbol: "FB")).to eq(state: :renamed, current_symbol: "META")
  end

  it "reports a symbol the catalogue has never heard of" do
    create(:asset, symbol: "META", former_symbols: [ "FB" ])

    expect(described_class.call(symbol: "GONE")).to eq(state: :missing)
  end

  it "prefers the live listing when a former symbol was reused" do
    create(:asset, symbol: "FB")
    create(:asset, symbol: "META", former_symbols: [ "FB" ])

    expect(described_class.call(symbol: "FB")).to eq(state: :listed)
  end
end
