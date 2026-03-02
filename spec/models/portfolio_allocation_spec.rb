require "rails_helper"

RSpec.describe Portfolio do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  describe "#allocation_by_sector" do
    it "groups open positions by sector" do
      tech_asset = create(:asset, :stock, sector: "Technology", current_price: 100)
      health_asset = create(:asset, :stock, sector: "Healthcare", current_price: 50)
      create(:position, portfolio: portfolio, asset: tech_asset, shares: 10, status: :open)
      create(:position, portfolio: portfolio, asset: health_asset, shares: 20, status: :open)

      allocation = portfolio.allocation_by_sector

      expect(allocation["Technology"]).to eq(1_000)
      expect(allocation["Healthcare"]).to eq(1_000)
    end

    it "excludes closed positions" do
      asset = create(:asset, :stock, sector: "Technology", current_price: 100)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :closed)

      allocation = portfolio.allocation_by_sector

      expect(allocation).to be_empty
    end
  end

  describe "#allocation_by_asset_type" do
    it "groups open positions by asset type" do
      stock = create(:asset, :stock, current_price: 100)
      crypto = create(:asset, :crypto, current_price: 200)
      create(:position, portfolio: portfolio, asset: stock, shares: 5, status: :open)
      create(:position, portfolio: portfolio, asset: crypto, shares: 3, status: :open)

      allocation = portfolio.allocation_by_asset_type

      expect(allocation["stock"]).to eq(500)
      expect(allocation["crypto"]).to eq(600)
    end

    it "excludes closed positions" do
      asset = create(:asset, :stock, current_price: 100)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :closed)

      allocation = portfolio.allocation_by_asset_type

      expect(allocation).to be_empty
    end
  end
end
