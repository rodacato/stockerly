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

    let!(:aapl_position) do
      create(:position, portfolio: portfolio, asset: aapl, shares: 10, avg_cost: 100.0, status: :open)
    end
    let!(:cetes_position) do
      create(:position, portfolio: portfolio, asset: cetes, shares: 500, avg_cost: 9.5, status: :open)
    end

    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: 0.0571429)

      # Each open position is backed by a buy trade with the FX rate captured
      # at execution. fx_rate_at_execution for AAPL matches today's USD->MXN
      # in this describe so the cost basis and current FX agree; the
      # historical-FX scenario where they DIVERGE is exercised in the
      # "historical-FX cost basis" describe below.
      create(:trade, portfolio: portfolio, position: aapl_position, asset: aapl,
                     side: :buy, shares: 10, price_per_share: 100.0,
                     currency: "USD", fx_rate_at_execution: 17.5)
      create(:trade, portfolio: portfolio, position: cetes_position, asset: cetes,
                     side: :buy, shares: 500, price_per_share: 9.5,
                     currency: "MXN", fx_rate_at_execution: 1.0)
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
      it "uses market_value (current FX) minus cost_basis (historical FX)" do
        # AAPL market value MXN = 10 × $150 × 17.5 = 26,250
        # AAPL cost basis  MXN = 10 × $100 × 17.5 = 17,500 (trade FX matches today)
        # AAPL gain        MXN = 8,750
        # CETES market value MXN = 500 × 10 = 5,000
        # CETES cost basis   MXN = 500 × 9.5 × 1.0 = 4,750
        # CETES gain         MXN = 250
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

    describe "Portfolio#total_value FX caching" do
      it "issues only one FxRate.find_by per (from, to) pair across positions" do
        # Add a second USD position so we'd see a redundant lookup if the
        # cache weren't doing its job.
        second_usd = create(:asset, symbol: "MSFT", currency: "USD",
                                    current_price: 200.0, sector: "Technology")
        msft_position = create(:position, portfolio: portfolio, asset: second_usd,
                                          shares: 5, avg_cost: 150.0, status: :open)
        create(:trade, portfolio: portfolio, position: msft_position, asset: second_usd,
                       side: :buy, shares: 5, price_per_share: 150.0,
                       currency: "USD", fx_rate_at_execution: 17.5)

        # Reload the portfolio so its memoized FX cache starts empty.
        portfolio.reload
        expect(FxRate).to receive(:find_by).with(base_currency: "USD", quote_currency: "MXN").once.and_call_original
        portfolio.total_value(currency: "MXN")
      end
    end
  end

  describe "PortfolioSummary with historical FX divergence" do
    let(:user)      { create(:user, preferred_currency: "MXN") }
    let(:portfolio) { create(:portfolio, user: user, buying_power: 0) }
    let(:aapl)      { create(:asset, symbol: "AAPL", currency: "USD", current_price: 150.0) }
    let(:summary)   { Trading::Domain::PortfolioSummary.new(portfolio) }

    let!(:position) do
      create(:position, portfolio: portfolio, asset: aapl, shares: 10, avg_cost: 100.0, status: :open)
    end

    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      # AAPL was bought when USD->MXN was 18.0 (peso has since strengthened).
      create(:trade, portfolio: portfolio, position: position, asset: aapl,
                     side: :buy, shares: 10, price_per_share: 100.0,
                     currency: "USD", fx_rate_at_execution: 18.0)
    end

    it "computes total_invested using each trade's historical FX rate" do
      # 10 × $100 × 18.0 = 18,000 MXN (historical FX, not today's 17.5)
      expect(summary.total_invested).to eq(18_000.to_d)
    end

    it "captures principal FX loss in unrealized_gain (not just price delta)" do
      # market value MXN: 10 × $150 × 17.5 = 26,250
      # cost basis  MXN: 10 × $100 × 18.0 = 18,000
      # gain        MXN: 26,250 - 18,000 = 8,250
      gain = summary.unrealized_gain
      expect(gain.absolute).to eq(8_250.0)
      # Percent: 8250 / 18000 * 100 = 45.83%
      expect(gain.percent).to be_within(0.01).of(45.83)
    end

    it "reports an FX-only loss when the asset price has not moved" do
      # If AAPL's current_price equals the original $100 but FX dropped from
      # 18.0 to 17.5, the user still lost ground in MXN — the previous
      # implementation reported zero gain because the asset-currency delta
      # was zero.
      aapl.update!(current_price: 100.0)
      # market value MXN: 10 × $100 × 17.5 = 17,500
      # cost basis  MXN: 10 × $100 × 18.0 = 18,000
      # gain        MXN: -500
      expect(portfolio.total_unrealized_gain(currency: "MXN")).to eq(-500.to_d)
    end
  end

  describe "missing fx_rate_at_execution on a buy trade" do
    let(:user)      { create(:user, preferred_currency: "MXN") }
    let(:portfolio) { create(:portfolio, user: user, buying_power: 0) }
    let(:aapl)      { create(:asset, symbol: "AAPL", currency: "USD", current_price: 150.0) }

    let!(:position) do
      create(:position, portfolio: portfolio, asset: aapl, shares: 10, avg_cost: 100.0, status: :open)
    end

    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      # Legacy trade row with no FX captured (pre-S2 data).
      create(:trade, portfolio: portfolio, position: position, asset: aapl,
                     side: :buy, shares: 10, price_per_share: 100.0,
                     currency: "USD", fx_rate_at_execution: nil)
    end

    it "raises rather than silently treating the FX rate as zero" do
      expect { Trading::Domain::PortfolioSummary.new(portfolio).total_invested }
        .to raise_error(/missing fx_rate_at_execution/)
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
      # (Position has no trades; same-currency fast path in avg_cost_in
      # returns the raw avg_cost so cost basis equals shares × avg_cost.)
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
