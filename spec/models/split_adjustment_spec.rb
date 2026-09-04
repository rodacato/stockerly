require "rails_helper"

RSpec.describe SplitAdjustment, type: :model do
  subject(:adjustment) { build(:split_adjustment) }

  describe "associations" do
    it "belongs to an asset" do
      expect(adjustment.asset).to be_a(Asset)
    end
  end

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires ex_date" do
      adjustment.ex_date = nil
      expect(adjustment).not_to be_valid
    end

    it "requires positive ratio_from" do
      adjustment.ratio_from = 0
      expect(adjustment).not_to be_valid
    end

    it "requires positive ratio_to" do
      adjustment.ratio_to = 0
      expect(adjustment).not_to be_valid
    end
  end

  # The guard the handler leans on: the database refuses the second row rather
  # than a validation, so two workers cannot both pass the check.
  it "refuses a second adjustment for the same asset and ex-date" do
    existing = create(:split_adjustment)

    expect {
      described_class.create!(
        asset: existing.asset, ex_date: existing.ex_date, ratio_from: 1, ratio_to: 2
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
