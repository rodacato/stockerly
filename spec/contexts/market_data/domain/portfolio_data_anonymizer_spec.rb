require "rails_helper"

RSpec.describe MarketData::Domain::PortfolioDataAnonymizer do
  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user: user) }

  let(:tech_asset) { create(:asset, symbol: "AAPL", current_price: 200.0, sector: "Technology") }
  let(:energy_asset) { create(:asset, symbol: "OKE", current_price: 80.0, sector: "Energy") }

  before do
    create(:position, portfolio: portfolio, asset: tech_asset, shares: 10, status: :open)
    create(:position, portfolio: portfolio, asset: energy_asset, shares: 5, status: :open)
  end

  let(:summary) do
    {
      weekly_change: 3.456,
      top_performer: { symbol: "AAPL", change_percent: 5.678 },
      worst_performer: { symbol: "OKE", change_percent: -1.234 }
    }
  end

  let(:concentration) { { hhi: 2500, label: "Moderate" } }

  it "extracts percentage-only data from portfolio" do
    result = described_class.anonymize(portfolio: portfolio, summary: summary, concentration: concentration)

    expect(result[:weekly_change]).to eq(3.46)
    expect(result[:top_performer]).to eq({ symbol: "AAPL", change_percent: 5.68 })
    expect(result[:position_count]).to eq(2)
    expect(result[:concentration_hhi]).to eq(2500)
    expect(result[:sector_weights]).to include("Technology", "Energy")
  end

  it "excludes dollar amounts from output" do
    result = described_class.anonymize(portfolio: portfolio, summary: summary, concentration: concentration)

    flat = result.to_s
    expect(flat).not_to include("200.0")
    expect(flat).not_to include("80.0")
  end

  it "handles missing concentration data gracefully" do
    result = described_class.anonymize(portfolio: portfolio, summary: summary, concentration: nil)

    expect(result[:concentration_hhi]).to be_nil
    expect(result[:risk_level]).to be_nil
  end
end
