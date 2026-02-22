require "rails_helper"

RSpec.describe RecalculateAvgCostOnTrade do
  describe ".call" do
    let(:user) { create(:user) }
    let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
    let(:asset) { create(:asset, current_price: 100) }
    let(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 90, status: :open) }

    it "calls recalculate_avg_cost! on the position" do
      allow(Position).to receive(:find_by).with(id: position.id).and_return(position)
      allow(position).to receive(:recalculate_avg_cost!)

      described_class.call(position_id: position.id)

      expect(position).to have_received(:recalculate_avg_cost!)
    end

    it "does nothing when position not found" do
      expect { described_class.call(position_id: -1) }.not_to raise_error
    end
  end
end
