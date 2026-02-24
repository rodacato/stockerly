require "rails_helper"

RSpec.describe RecalculateAvgCostOnTrade do
  describe ".call" do
    let(:user) { create(:user) }
    let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
    let(:asset) { create(:asset, current_price: 100) }
    let(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 90, status: :open) }

    it "calls recalculate_avg_cost! on the position with a lock" do
      allow(Position).to receive(:find_by).with(id: position.id).and_return(position)
      allow(position).to receive(:with_lock).and_yield
      allow(position).to receive(:recalculate_avg_cost!)

      described_class.call(position_id: position.id)

      expect(position).to have_received(:with_lock)
      expect(position).to have_received(:recalculate_avg_cost!)
    end

    it "does nothing when position not found" do
      expect { described_class.call(position_id: -1) }.not_to raise_error
    end

    it "recalculates from buy trades within a transaction lock" do
      create(:trade, portfolio: portfolio, asset: asset, position: position,
        side: :buy, shares: 10, price_per_share: 100.0, total_amount: 1_000.0)
      create(:trade, portfolio: portfolio, asset: asset, position: position,
        side: :buy, shares: 20, price_per_share: 150.0, total_amount: 3_000.0)

      described_class.call(position_id: position.id)

      position.reload
      expect(position.avg_cost.to_f).to be_within(0.01).of(133.33)
    end
  end
end
