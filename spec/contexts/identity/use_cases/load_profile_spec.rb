require "rails_helper"

RSpec.describe Identity::UseCases::LoadProfile do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns Success with watchlist_items" do
      asset = create(:asset, symbol: "AAPL")
      create(:watchlist_item, user: user, asset: asset)

      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data[:watchlist_items].count).to eq(1)
      expect(data[:watchlist_items].first.asset.symbol).to eq("AAPL")
    end

    it "returns empty watchlist for new user" do
      result = described_class.call(user: user)
      expect(result.value![:watchlist_items]).to be_empty
    end
  end
end
