require "rails_helper"

RSpec.describe Trading::Domain::SplitAdjuster do
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
  describe "applying twice" do
    it "leaves the same numbers as applying once" do
      described_class.new(stock_split).adjust!
      described_class.new(stock_split.reload).adjust!

      expect(position.reload.shares).to eq(400)
      expect(position.avg_cost).to eq(50.0)
    end

    it "records that the split landed" do
      expect { described_class.new(stock_split).adjust! }
        .to change { stock_split.reload.applied_at }.from(nil)
    end

    it "does not touch trades on the second pass" do
      trade = create(:trade, portfolio: portfolio, asset: asset, position: position,
                             side: :buy, shares: 10, price_per_share: 200.0,
                             executed_at: 5.days.ago)

      described_class.new(stock_split).adjust!
      described_class.new(stock_split.reload).adjust!

      expect(trade.reload.shares).to eq(40)
      expect(trade.price_per_share).to eq(50.0)
    end
  end

  describe "when the adjustment fails partway" do
    it "rolls back the positions it had already rewritten" do
      allow(Trade).to receive(:where).and_raise(ActiveRecord::StatementInvalid, "boom")

      expect { described_class.new(stock_split).adjust! }.to raise_error(ActiveRecord::StatementInvalid)

      expect(position.reload.shares).to eq(100)
      expect(stock_split.reload.applied_at).to be_nil
    end
  end
end
