require "rails_helper"

RSpec.describe TakeSnapshotsJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user) }
    let!(:portfolio) { create(:portfolio, user: user, buying_power: 5000) }

    it "creates a snapshot for each portfolio" do
      expect {
        described_class.perform_now
      }.to change(PortfolioSnapshot, :count).by(1)

      snapshot = PortfolioSnapshot.last
      expect(snapshot.portfolio).to eq(portfolio)
      expect(snapshot.date).to eq(Date.current)
      expect(snapshot.cash_value.to_f).to eq(5000.0)
    end

    it "is idempotent — does not duplicate snapshots" do
      described_class.perform_now

      expect {
        described_class.perform_now
      }.not_to change(PortfolioSnapshot, :count)
    end

    context "with open positions" do
      let(:asset) { create(:asset, current_price: 100) }

      before do
        create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 90, status: :open)
      end

      it "calculates invested_value from positions" do
        described_class.perform_now

        snapshot = PortfolioSnapshot.last
        expect(snapshot.invested_value.to_f).to eq(1000.0) # 10 shares * $100
        expect(snapshot.total_value.to_f).to eq(6000.0)    # 1000 + 5000 buying_power
      end
    end
  end
end
