require "rails_helper"

RSpec.describe MarketData::Queries::AssetSectors do
  def overview(asset, sector)
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW", metrics: { "sector" => sector })
  end

  it "reads the column, and the provider's overview where the column is blank" do
    named = create(:asset, :stock, symbol: "AAPL", sector: "Technology")
    blank = create(:asset, :stock, symbol: "AVGO", sector: nil)
    overview(blank, "Technology")
    both = create(:asset, :stock, symbol: "COIN", sector: "Financial Services")
    overview(both, "Technology")

    result = described_class.call(assets: [ named, blank, both ])

    expect(result).to eq(named.id => "Technology", blank.id => "Technology", both.id => "Financial Services")
  end

  it "has no sector for an asset neither source classifies" do
    etf = create(:asset, :etf, symbol: "VOO", sector: nil)

    expect(described_class.call(assets: [ etf ])).to eq(etf.id => nil)
  end
end
