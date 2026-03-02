require "rails_helper"

RSpec.describe Identity::CompleteWizard do
  let(:user) { create(:user) }
  let(:asset1) { create(:asset, symbol: "AAPL") }
  let(:asset2) { create(:asset, symbol: "TSLA") }

  describe ".call" do
    it "adds selected assets to watchlist" do
      result = described_class.call(user: user, asset_ids: [ asset1.id, asset2.id ])

      expect(result).to be_success
      expect(user.watchlist_items.count).to eq(2)
    end

    it "does not create duplicate watchlist items" do
      create(:watchlist_item, user: user, asset: asset1)

      result = described_class.call(user: user, asset_ids: [ asset1.id, asset2.id ])
      expect(result).to be_success
      expect(user.watchlist_items.count).to eq(2)
    end

    it "sets onboarded_at timestamp" do
      expect(user.onboarded_at).to be_nil

      described_class.call(user: user, asset_ids: [ asset1.id ])

      user.reload
      expect(user.onboarded_at).to be_present
    end

    it "handles empty asset_ids gracefully" do
      result = described_class.call(user: user, asset_ids: [])
      expect(result).to be_success
      expect(user.onboarded_at).to be_present
    end
  end
end
