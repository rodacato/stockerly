require "rails_helper"

RSpec.describe Portfolio, type: :model do
  subject(:portfolio) { build(:portfolio) }

  describe "validations" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    let(:user)      { create(:user) }
    let(:portfolio) { create(:portfolio, user: user) }

    it "belongs to user" do
      expect(portfolio.user).to eq(user)
    end

    it "destroys positions on destroy" do
      asset = create(:asset)
      create(:position, portfolio: portfolio, asset: asset)
      expect { portfolio.destroy }.to change(Position, :count).by(-1)
    end

    it "destroys trades on destroy" do
      asset = create(:asset)
      create(:trade, portfolio: portfolio, asset: asset)
      expect { portfolio.destroy }.to change(Trade, :count).by(-1)
    end
  end

  describe "#open_positions / #closed_positions" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset) }
    let!(:open_pos)   { create(:position, portfolio: portfolio, asset: asset, status: :open) }
    let!(:closed_pos) { create(:position, portfolio: portfolio, asset: create(:asset), status: :closed, closed_at: Time.current) }

    it "#open_positions returns only open" do
      expect(portfolio.open_positions).to contain_exactly(open_pos)
    end

    it "#closed_positions returns only closed" do
      expect(portfolio.closed_positions).to contain_exactly(closed_pos)
    end
  end

  describe "#total_value" do
    let(:portfolio) { create(:portfolio, buying_power: 1_000) }
    let(:asset)     { create(:asset, current_price: 100.0) }

    it "sums open position values plus buying power" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      expect(portfolio.total_value).to eq(2_000.0)
    end

    it "returns only buying power when no positions" do
      expect(portfolio.total_value).to eq(1_000.0)
    end
  end

  describe "#total_unrealized_gain" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset, current_price: 150.0) }

    it "calculates unrealized gain from open positions" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0, status: :open)
      expect(portfolio.total_unrealized_gain).to eq(500.0)
    end
  end

  describe "#yesterday_snapshot" do
    let(:portfolio) { create(:portfolio) }

    it "returns nil when no snapshot exists" do
      expect(portfolio.yesterday_snapshot).to be_nil
    end

    it "returns yesterday's snapshot" do
      snap = create(:portfolio_snapshot, portfolio: portfolio, date: Date.yesterday)
      expect(portfolio.yesterday_snapshot).to eq(snap)
    end
  end
end
