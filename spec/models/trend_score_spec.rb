require "rails_helper"

RSpec.describe TrendScore, type: :model do
  subject(:score) { build(:trend_score) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires score" do
      score.score = nil
      expect(score).not_to be_valid
    end

    it "requires score between 0 and 100" do
      score.score = 101
      expect(score).not_to be_valid
    end

    it "accepts score of 0" do
      score.score = 0
      expect(score).to be_valid
    end

    it "accepts score of 100" do
      score.score = 100
      expect(score).to be_valid
    end
  end

  describe "enums" do
    it "defines label enum with 6 values" do
      expect(TrendScore.labels.keys).to contain_exactly(
        "weak", "moderate", "strong", "parabolic", "sideways", "weakening"
      )
    end

    it "defines direction enum" do
      expect(TrendScore.directions).to eq("upward" => 0, "downward" => 1)
    end
  end

  describe "scopes" do
    it ".latest orders by calculated_at desc" do
      asset = create(:asset)
      old = create(:trend_score, asset: asset, calculated_at: 2.days.ago)
      recent = create(:trend_score, asset: asset, calculated_at: 1.hour.ago)
      expect(TrendScore.latest.first).to eq(recent)
    end
  end
end
