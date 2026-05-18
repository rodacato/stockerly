require "rails_helper"

RSpec.describe TakeSnapshotsJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user, preferred_currency: "USD") }
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

    it "persists the user's preferred_currency on each snapshot" do
      described_class.perform_now
      expect(PortfolioSnapshot.last.currency).to eq("USD")
    end

    it "is idempotent — does not duplicate snapshots" do
      described_class.perform_now

      expect {
        described_class.perform_now
      }.not_to change(PortfolioSnapshot, :count)
    end

    context "with open positions in the same currency as preferred" do
      let(:asset) { create(:asset, currency: "USD", current_price: 100) }

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

    context "with mixed-currency positions (Lucía invariant)" do
      let(:user)      { create(:user, preferred_currency: "MXN") }
      let!(:portfolio) { create(:portfolio, user: user, buying_power: 1_000) }

      let(:mxn_asset) { create(:asset, :mexican, currency: "MXN", current_price: 200) }
      let(:usd_asset) { create(:asset, currency: "USD", current_price: 100) }

      before do
        create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0, fetched_at: Time.current)
        create(:position, portfolio: portfolio, asset: mxn_asset, shares: 5,  avg_cost: 180, status: :open)
        create(:position, portfolio: portfolio, asset: usd_asset, shares: 2,  avg_cost: 90,  status: :open)
      end

      it "converts each position to preferred_currency before summing" do
        described_class.perform_now

        snapshot = PortfolioSnapshot.last
        # 5 × 200 MXN + 2 × 100 USD × 17 MXN/USD = 1000 + 3400 = 4400 MXN
        expect(snapshot.invested_value.to_f).to eq(4400.0)
        # invested 4400 + buying_power 1000 (already MXN) = 5400 MXN
        expect(snapshot.total_value.to_f).to eq(5400.0)
        expect(snapshot.cash_value.to_f).to eq(1000.0)
        expect(snapshot.currency).to eq("MXN")
      end

      it "is NOT the naive cross-currency sum (regression guard)" do
        described_class.perform_now

        # The pre-fix bug would have produced: 5×200 + 2×100 + 1000 = 2200 MXN+USD garbage
        snapshot = PortfolioSnapshot.last
        expect(snapshot.total_value.to_f).not_to eq(2200.0)
      end
    end
  end
end
