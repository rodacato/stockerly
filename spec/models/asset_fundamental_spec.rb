require "rails_helper"

RSpec.describe AssetFundamental, type: :model do
  subject(:fundamental) { build(:asset_fundamental) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires period_label" do
      fundamental.period_label = nil
      expect(fundamental).not_to be_valid
    end

    it "requires metrics" do
      fundamental.metrics = nil
      expect(fundamental).not_to be_valid
    end

    it "belongs to asset" do
      fundamental.asset = nil
      expect(fundamental).not_to be_valid
    end
  end

  describe "scopes" do
    let(:asset) { create(:asset) }
    let!(:overview) { create(:asset_fundamental, asset: asset, period_label: "OVERVIEW", calculated_at: 1.day.ago) }
    let!(:ttm) { create(:asset_fundamental, :ttm, asset: asset, calculated_at: 2.hours.ago) }

    it ".overview returns OVERVIEW records" do
      expect(described_class.overview).to contain_exactly(overview)
    end

    it ".ttm returns TTM records" do
      expect(described_class.ttm).to contain_exactly(ttm)
    end

    it ".for_asset filters by asset_id" do
      other = create(:asset_fundamental, asset: create(:asset, symbol: "GOOGL"))
      expect(described_class.for_asset(asset.id)).to contain_exactly(overview, ttm)
      expect(described_class.for_asset(asset.id)).not_to include(other)
    end

    it ".latest orders by calculated_at desc" do
      expect(described_class.latest.first).to eq(ttm)
    end
  end

  describe "uniqueness constraint" do
    let(:asset) { create(:asset) }

    it "enforces unique [asset_id, period_label]" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW")

      duplicate = build(:asset_fundamental, asset: asset, period_label: "OVERVIEW")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
