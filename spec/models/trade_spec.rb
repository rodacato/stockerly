require "rails_helper"

RSpec.describe Trade, type: :model do
  subject(:trade) { build(:trade) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires shares" do
      trade.shares = nil
      expect(trade).not_to be_valid
    end

    it "requires shares greater than 0" do
      trade.shares = 0
      expect(trade).not_to be_valid
    end

    it "requires price_per_share" do
      trade.price_per_share = nil
      expect(trade).not_to be_valid
    end

    it "requires executed_at" do
      trade.executed_at = nil
      expect(trade).not_to be_valid
    end
  end

  describe "enums" do
    it "defines side enum" do
      expect(Trade.sides).to eq("buy" => 0, "sell" => 1)
    end
  end

  describe "callbacks" do
    it "calculates total_amount on create" do
      trade = build(:trade, shares: 5, price_per_share: 200.0, total_amount: nil)
      trade.save!
      expect(trade.total_amount.to_f).to eq(1_000.0)
    end
  end

  describe "scopes" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset) }

    it ".buys returns only buy trades" do
      buy = create(:trade, portfolio: portfolio, asset: asset, side: :buy)
      sell = create(:trade, portfolio: portfolio, asset: asset, side: :sell)
      expect(Trade.buys).to contain_exactly(buy)
    end

    it ".sells returns only sell trades" do
      buy = create(:trade, portfolio: portfolio, asset: asset, side: :buy)
      sell = create(:trade, portfolio: portfolio, asset: asset, side: :sell)
      expect(Trade.sells).to contain_exactly(sell)
    end

    it ".recent orders by executed_at desc" do
      old = create(:trade, portfolio: portfolio, asset: asset, executed_at: 2.days.ago)
      recent = create(:trade, portfolio: portfolio, asset: asset, executed_at: 1.hour.ago)
      expect(Trade.recent.first).to eq(recent)
    end
  end

  describe "associations" do
    it "allows nil position" do
      trade = build(:trade, position: nil)
      expect(trade).to be_valid
    end
  end
end
