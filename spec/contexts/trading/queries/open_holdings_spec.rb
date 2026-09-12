require "rails_helper"

RSpec.describe Trading::Queries::OpenHoldings do
  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, current_price: 190) }

  it "returns plain data, never Position records — that is the boundary (ADR-025)" do
    create(:position, portfolio: portfolio, asset: asset, shares: 12, status: :open)

    holdings = described_class.call(user: user)

    expect(holdings.first).to be_a(Hash)
    expect(holdings.first.keys).to contain_exactly(:symbol, :asset_type, :shares, :market_value)
  end

  it "carries the four facts a caller needs to reason about a holding" do
    create(:position, portfolio: portfolio, asset: asset, shares: 12, status: :open)

    holding = described_class.call(user: user).first

    expect(holding[:symbol]).to eq("AAPL")
    expect(holding[:asset_type]).to eq("stock")
    expect(holding[:shares]).to eq(12)
    expect(holding[:market_value]).to be_present
  end

  it "excludes closed positions, which are history rather than holdings" do
    create(:position, portfolio: portfolio, asset: asset, shares: 12, status: :closed)

    expect(described_class.call(user: user)).to be_empty
  end

  it "returns nothing for a user with no portfolio instead of raising" do
    expect(described_class.call(user: create(:user))).to eq([])
  end

  it "returns nothing rather than raising when given no user at all" do
    expect(described_class.call(user: nil)).to eq([])
  end
end
