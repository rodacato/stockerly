require "rails_helper"

# End-to-end currency-aware portfolio behavior. The lie this PR fixes:
# Portfolio#total_value used to sum raw asset-currency BigDecimals across
# positions, then add buying_power on top — producing a number that
# looked plausible (because Ruby is happy to add 1500 + 1000 = 2500)
# but conflated USD with MXN as if they were the same unit.
#
# Now every aggregate accepts a currency: kwarg and converts each
# position via FxRate before summing. These specs lock in the expected
# numbers for a representative mixed MXN+USD portfolio and assert
# regression for the single-currency case.
RSpec.describe "Multi-currency portfolio", type: :model do
  describe "MXN-preferred user with mixed MXN + USD positions" do
    let(:user)      { create(:user, preferred_currency: "MXN") }
    let(:portfolio) { create(:portfolio, user: user, buying_power: 10_000) } # MXN

    let(:aapl) do
      create(:asset, symbol: "AAPL", currency: "USD", current_price: 150.0, sector: "Technology")
    end
    let(:cetes) do
      create(:asset, symbol: "CETES28", currency: "MXN", asset_type: :fixed_income,
                     current_price: 10.0, sector: "Government")
    end

    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: 0.0571429)

      create(:position, portfolio: portfolio, asset: aapl,  shares: 10,  avg_cost: 100.0, status: :open)
      create(:position, portfolio: portfolio, asset: cetes, shares: 500, avg_cost: 9.5,   status: :open)
    end

    describe "Portfolio#total_value" do
      it "converts each position to MXN and adds MXN buying_power" do
        # AAPL: 10 × $150 = $1500 USD × 17.5 = 26,250 MXN
        # CETES: 500 × 10 MXN = 5,000 MXN (native)
        # buying_power: 10,000 MXN
        # Total: 41,250 MXN
        expect(portfolio.total_value(currency: "MXN")).to eq(41_250.to_d)
      end

      it "defaults to user.preferred_currency when no kwarg" do
        expect(portfolio.total_value).to eq(41_250.to_d)
      end
    end

    describe "Portfolio#total_unrealized_gain" do
      it "converts each position's gain to MXN" do
        # AAPL: 10 × ($150 - $100) = $500 USD × 17.5 = 8,750 MXN
        # CETES: 500 × (10 - 9.5) = 250 MXN
        # Total: 9,000 MXN
        expect(portfolio.total_unrealized_gain(currency: "MXN")).to eq(9_000.to_d)
      end
    end

    describe "Portfolio#allocation_by_sector" do
      it "returns MXN-converted weights per sector" do
        result = portfolio.allocation_by_sector(currency: "MXN")
        expect(result["Technology"]).to eq(26_250.to_d) # AAPL in MXN
        expect(result["Government"]).to eq(5_000.to_d)  # CETES native MXN
      end
    end

    describe "PortfolioSummary#total_invested with historical-FX cost basis" do
      let(:summary) { Trading::Domain::PortfolioSummary.new(portfolio) }

      before do
        # Backfill the buy trades that produced these positions, each with
        # the FX rate at the trade's execution time.
        aapl_position = portfolio.positions.find_by(asset: aapl)
        cetes_position = portfolio.positions.find_by(asset: cetes)

        # AAPL was bought when USD->MXN was 18.0 (slightly higher than today's 17.5)
        create(:trade, portfolio: portfolio, position: aapl_position, asset: aapl,
                       side: :buy, shares: 10, price_per_share: 100.0,
                       currency: "USD", fx_rate_at_execution: 18.0)

        # CETES was bought at the native rate of 1 (MXN->MXN)
        create(:trade, portfolio: portfolio, position: cetes_position, asset: cetes,
                       side: :buy, shares: 500, price_per_share: 9.5,
                       currency: "MXN", fx_rate_at_execution: 1.0)
      end

      it "computes total_invested using each trade's historical FX rate" do
        # AAPL: 10 × $100 × 18.0 = 18,000 MXN  (historical FX, not today's 17.5)
        # CETES: 500 × 9.5 × 1.0 = 4,750 MXN
        # Total: 22,750 MXN
        expect(summary.total_invested).to eq(22_750.to_d)
      end

      it "computes unrealized_gain percent using historical-FX cost basis" do
        # gain (MXN): 9,000  |  invested (MXN): 22,750
        # percent: 9000/22750 * 100 = 39.56%
        gain = summary.unrealized_gain
        expect(gain.absolute).to eq(9_000.0)
        expect(gain.percent).to be_within(0.01).of(39.56)
      end
    end
  end

  describe "USD-preferred user with USD-only positions (regression)" do
    let(:user)      { create(:user, preferred_currency: "USD") }
    let(:portfolio) { create(:portfolio, user: user, buying_power: 1_000) }
    let(:asset)     { create(:asset, currency: "USD", current_price: 100.0) }

    before do
      create(:position, portfolio: portfolio, asset: asset, shares: 10,
                        avg_cost: 80.0, status: :open)
    end

    it "matches the pre-currency-aware total_value calculation" do
      # 10 × 100 + 1000 = 2000 — same as before the refactor
      expect(portfolio.total_value(currency: "USD")).to eq(2_000.to_d)
    end

    it "matches the pre-currency-aware total_unrealized_gain calculation" do
      # 10 × (100 - 80) = 200 — same as before
      expect(portfolio.total_unrealized_gain(currency: "USD")).to eq(200.to_d)
    end

    it "does not consult FxRate for same-currency portfolios" do
      # Drop all FX rates to prove the calculation never reaches FxRate
      FxRate.delete_all
      expect { portfolio.total_value(currency: "USD") }.not_to raise_error
      expect(portfolio.total_value(currency: "USD")).to eq(2_000.to_d)
    end
  end

  describe "missing FX rate" do
    let(:user)      { create(:user, preferred_currency: "MXN") }
    let(:portfolio) { create(:portfolio, user: user, buying_power: 0) }
    let(:asset)     { create(:asset, currency: "USD", current_price: 100.0) }

    before do
      create(:position, portfolio: portfolio, asset: asset, shares: 1,
                        avg_cost: 100.0, status: :open)
      # No USD->MXN FxRate row deliberately.
    end

    it "raises loudly when conversion is required but no rate is seeded" do
      expect { portfolio.total_value(currency: "MXN") }.to raise_error(/Missing FX rate USD->MXN/)
    end
  end
end
