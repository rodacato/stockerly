require "rails_helper"

RSpec.describe AssetPriceHistory, type: :model do
  subject(:history) { build(:asset_price_history) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires date" do
      history.date = nil
      expect(history).not_to be_valid
    end

    it "requires close" do
      history.close = nil
      expect(history).not_to be_valid
    end

    it "requires unique date per asset" do
      asset = create(:asset)
      create(:asset_price_history, asset: asset, date: "2026-02-20")
      dup = build(:asset_price_history, asset: asset, date: "2026-02-20")
      expect(dup).not_to be_valid
    end
  end

  describe "scopes" do
    let(:asset) { create(:asset) }

    it ".for_period returns records within date range" do
      jan = create(:asset_price_history, asset: asset, date: "2026-01-15")
      feb = create(:asset_price_history, asset: asset, date: "2026-02-15")
      mar = create(:asset_price_history, asset: asset, date: "2026-03-15")
      result = AssetPriceHistory.for_period(Date.new(2026, 1, 1), Date.new(2026, 2, 28))
      expect(result).to contain_exactly(jan, feb)
    end

    it ".recent returns records from last N days" do
      recent = create(:asset_price_history, asset: asset, date: 5.days.ago)
      old = create(:asset_price_history, asset: asset, date: 60.days.ago)
      expect(AssetPriceHistory.recent(30)).to contain_exactly(recent)
    end
  end
end
