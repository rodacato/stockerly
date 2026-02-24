require "rails_helper"

RSpec.describe Position, type: :model do
  subject(:position) { build(:position) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires shares" do
      position.shares = nil
      expect(position).not_to be_valid
    end

    it "allows shares of 0 (for closed positions)" do
      position.shares = 0
      expect(position).to be_valid
    end

    it "rejects negative shares" do
      position.shares = -1
      expect(position).not_to be_valid
    end

    it "requires avg_cost" do
      position.avg_cost = nil
      expect(position).not_to be_valid
    end

    it "requires avg_cost greater than 0" do
      position.avg_cost = 0
      expect(position).not_to be_valid
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(Position.statuses).to eq("open" => 0, "closed" => 1)
    end
  end

  describe "scopes" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset) }
    let!(:domestic) { create(:position, portfolio: portfolio, asset: asset, currency: "USD") }
    let!(:international) { create(:position, portfolio: portfolio, asset: create(:asset), currency: "MXN") }

    it ".domestic returns USD positions" do
      expect(Position.domestic).to contain_exactly(domestic)
    end

    it ".international returns non-USD positions" do
      expect(Position.international).to contain_exactly(international)
    end
  end

  describe "#market_value" do
    it "calculates shares * current_price" do
      asset = create(:asset, current_price: 200.0)
      position = build(:position, asset: asset, shares: 10)
      expect(position.market_value).to eq(2_000.0)
    end

    it "handles nil current_price" do
      asset = create(:asset, current_price: nil)
      position = build(:position, asset: asset, shares: 10)
      expect(position.market_value).to eq(0)
    end
  end

  describe "#total_gain" do
    it "calculates unrealized gain" do
      asset = create(:asset, current_price: 150.0)
      position = build(:position, asset: asset, shares: 10, avg_cost: 100.0)
      expect(position.total_gain).to eq(500.0)
    end
  end

  describe "#total_gain_percent" do
    it "calculates gain as percentage" do
      asset = create(:asset, current_price: 150.0)
      position = build(:position, asset: asset, shares: 10, avg_cost: 100.0)
      expect(position.total_gain_percent).to eq(50.0)
    end

    it "returns 0 when avg_cost is zero" do
      asset = create(:asset, current_price: 150.0)
      position = build(:position, asset: asset, shares: 10, avg_cost: 0)
      position.valid? # skip validation for this test
      expect(position.total_gain_percent).to eq(0)
    end
  end

  describe "#recalculate_avg_cost!" do
    it "recalculates avg_cost from buy trades" do
      portfolio = create(:portfolio)
      asset = create(:asset)
      position = create(:position, portfolio: portfolio, asset: asset, avg_cost: 100.0, shares: 30)
      create(:trade, portfolio: portfolio, asset: asset, position: position, side: :buy, shares: 10, price_per_share: 100.0, total_amount: 1_000.0)
      create(:trade, portfolio: portfolio, asset: asset, position: position, side: :buy, shares: 20, price_per_share: 150.0, total_amount: 3_000.0)

      position.recalculate_avg_cost!
      # weighted avg = (10*100 + 20*150) / 30 = 4000/30 ≈ 133.33
      expect(position.avg_cost.to_f).to be_within(0.01).of(133.33)
    end

    it "does nothing when no buy trades exist" do
      position = create(:position, avg_cost: 100.0)
      position.recalculate_avg_cost!
      expect(position.avg_cost.to_f).to eq(100.0)
    end
  end
end
