require "rails_helper"

RSpec.describe StockSplit, type: :model do
  subject(:split) { build(:stock_split) }

  describe "associations" do
    it "belongs to an asset" do
      expect(split.asset).to be_a(Asset)
    end
  end

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires ex_date" do
      split.ex_date = nil
      expect(split).not_to be_valid
    end

    it "requires ratio_from" do
      split.ratio_from = nil
      expect(split).not_to be_valid
    end

    it "requires ratio_to" do
      split.ratio_to = nil
      expect(split).not_to be_valid
    end

    it "requires positive ratio_from" do
      split.ratio_from = 0
      expect(split).not_to be_valid
    end

    it "requires positive ratio_to" do
      split.ratio_to = 0
      expect(split).not_to be_valid
    end

    it "enforces uniqueness of ex_date per asset" do
      existing = create(:stock_split)
      duplicate = build(:stock_split, asset: existing.asset, ex_date: existing.ex_date)
      expect(duplicate).not_to be_valid
    end
  end

  describe "#ratio" do
    it "returns ratio_to / ratio_from as float" do
      split = build(:stock_split, ratio_from: 1, ratio_to: 4)
      expect(split.ratio).to eq(4.0)
    end
  end

  describe "#label" do
    it "returns human-readable label" do
      split = build(:stock_split, ratio_from: 1, ratio_to: 4)
      expect(split.label).to eq("1:4")
    end
  end
end
