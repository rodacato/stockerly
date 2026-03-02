require "rails_helper"

RSpec.describe Trading::SplitAdjuster do
  let(:asset) { create(:asset, :stock) }
  let(:portfolio) { create(:portfolio) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 200.0, status: :open) }
  let(:stock_split) { create(:stock_split, asset: asset, ex_date: 1.day.ago.to_date, ratio_from: 1, ratio_to: 4) }

  describe "#adjust!" do
    it "multiplies position shares by split ratio" do
      described_class.new(stock_split).adjust!
      expect(position.reload.shares).to eq(400)
    end

    it "divides position avg_cost by split ratio" do
      described_class.new(stock_split).adjust!
      expect(position.reload.avg_cost).to eq(50.0)
    end

    it "adjusts pre-split trade prices" do
      trade = create(:trade, portfolio: portfolio, asset: asset, position: position,
                     side: :buy, shares: 100, price_per_share: 200.0,
                     executed_at: 1.week.ago)

      described_class.new(stock_split).adjust!

      trade.reload
      expect(trade.shares).to eq(400)
      expect(trade.price_per_share).to eq(50.0)
    end

    it "does not adjust post-split trades" do
      trade = create(:trade, portfolio: portfolio, asset: asset, position: position,
                     side: :buy, shares: 10, price_per_share: 50.0,
                     executed_at: Time.current)

      described_class.new(stock_split).adjust!

      trade.reload
      expect(trade.shares).to eq(10)
      expect(trade.price_per_share).to eq(50.0)
    end

    it "adjusts closed positions too" do
      closed = create(:position, portfolio: portfolio, asset: asset, shares: 50, avg_cost: 200.0, status: :closed)

      described_class.new(stock_split).adjust!

      closed.reload
      expect(closed.shares).to eq(200)
      expect(closed.avg_cost).to eq(50.0)
    end
  end
end
