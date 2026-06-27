require "rails_helper"

RSpec.describe MarketData::Queries::UpcomingDividends do
  describe ".call" do
    let(:asset) { create(:asset, :stock) }

    it "returns upcoming dividends for the given assets, ordered by ex_date" do
      later   = create(:dividend, asset: asset, ex_date: 3.weeks.from_now.to_date)
      sooner  = create(:dividend, asset: asset, ex_date: 1.week.from_now.to_date)

      expect(described_class.call(asset_ids: [ asset.id ])).to eq([ sooner, later ])
    end

    it "excludes past dividends" do
      past = create(:dividend, asset: asset, ex_date: 1.week.ago.to_date)

      expect(described_class.call(asset_ids: [ asset.id ])).not_to include(past)
    end

    it "excludes dividends for assets not in the list" do
      other_asset = create(:asset, :stock)
      other_div   = create(:dividend, asset: other_asset, ex_date: 1.month.from_now.to_date)

      expect(described_class.call(asset_ids: [ asset.id ])).not_to include(other_div)
    end

    it "returns an empty relation when asset_ids is blank" do
      create(:dividend, asset: asset, ex_date: 1.week.from_now.to_date)

      expect(described_class.call(asset_ids: [])).to be_empty
    end

    it "eager-loads the asset to prevent N+1" do
      create(:dividend, asset: asset, ex_date: 1.week.from_now.to_date)

      result = described_class.call(asset_ids: [ asset.id ]).first
      expect(result.association(:asset)).to be_loaded
    end
  end
end
