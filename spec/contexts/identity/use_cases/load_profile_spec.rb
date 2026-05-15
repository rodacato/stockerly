require "rails_helper"

RSpec.describe Identity::UseCases::LoadProfile do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns the user's watchlist items ordered by created_at DESC" do
      asset = create(:asset, symbol: "AAPL")
      create(:watchlist_item, user: user, asset: asset)

      result = described_class.call(user: user)

      expect(result.count).to eq(1)
      expect(result.first.asset.symbol).to eq("AAPL")
    end

    it "returns an empty relation for a new user" do
      expect(described_class.call(user: user)).to be_empty
    end
  end
end
