require "rails_helper"

RSpec.describe Onboarding::LoadProgress do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns the watchlist count" do
      asset = create(:asset, symbol: "AAPL")
      create(:watchlist_item, user: user, asset: asset)

      result = described_class.call(user: user)

      expect(result).to be_success
      expect(result.value![:watchlist_count]).to eq(1)
    end

    it "returns zero for user with no watchlist items" do
      result = described_class.call(user: user)
      expect(result.value![:watchlist_count]).to eq(0)
    end
  end
end
