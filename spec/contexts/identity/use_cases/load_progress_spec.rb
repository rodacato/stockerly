require "rails_helper"

RSpec.describe Identity::UseCases::LoadProgress do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns the user's watchlist count" do
      asset = create(:asset, symbol: "AAPL")
      create(:watchlist_item, user: user, asset: asset)

      expect(described_class.call(user: user)).to eq(1)
    end

    it "returns 0 for a user with no watchlist items" do
      expect(described_class.call(user: user)).to eq(0)
    end
  end
end
