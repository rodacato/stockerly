require "rails_helper"

# Spec-first audit for S12 #168, derived from Lucía's audit scenario
# (docs/research/audit-2026-05-23/C1-lucia-mx-financial-domain.md §"Top 3 #1").
#
# Scenario: an MX investor with preferred_currency MXN holds USD-denominated
# AAPL purchased across two trades with different FX rates. Today's FX is
# different from both execution FXs. Each calculator must report numbers that
# match what the broker statement would show in MXN.
#
# Concrete numbers (so a regression is obvious from the spec output):
#
#   Trade 1: 10 AAPL @ USD 150, FX 17.05 → cost 25,575 MXN
#   Trade 2: 10 AAPL @ USD 160, FX 17.30 → cost 27,680 MXN
#   Total cost (MXN): 53,255 / 20 shares = 2,662.75 MXN/share avg cost
#   Today's price: USD 155, FX 17.50
#   Market value (MXN): 20 × 155 × 17.50 = 54,250
#   Unrealized gain (MXN): 54,250 - 53,255 = 995
#   Unrealized gain %: 995 / 53,255 × 100 ≈ 1.869%
#
# Note the inversion: USD-side the position shows 0 gain (avg cost 155 = price 155),
# but MXN-side shows +995 because the peso weakened between executions and today.
# This is exactly the FX-on-principal effect Portfolio#total_unrealized_gain's
# comment cites as the reason it was rewritten (see #57 commit history).

RSpec.describe "Multi-currency calculator audit (#168 — Lucía scenario)" do
  let(:user)      { create(:user, preferred_currency: "MXN") }
  let(:portfolio) { create(:portfolio, user: user, buying_power: 0) }
  let(:asset)     { create(:asset, symbol: "AAPL", currency: "USD", current_price: 155.0) }

  let!(:fx_today) do
    create(:fx_rate,
           base_currency: "USD",
           quote_currency: "MXN",
           rate: 17.50,
           fetched_at: Time.current)
  end

  let!(:position) do
    create(:position,
           portfolio: portfolio,
           asset: asset,
           shares: 20,
           avg_cost: 155.0,  # weighted USD avg: (150+160)/2
           status: :open)
  end

  let!(:trade1) do
    create(:trade,
           portfolio: portfolio,
           asset: asset,
           position: position,
           side: :buy,
           shares: 10,
           price_per_share: 150.0,
           total_amount: 1_500.0,
           currency: "USD",
           fx_rate_at_execution: 17.05,
           executed_at: 2.days.ago)
  end

  let!(:trade2) do
    create(:trade,
           portfolio: portfolio,
           asset: asset,
           position: position,
           side: :buy,
           shares: 10,
           price_per_share: 160.0,
           total_amount: 1_600.0,
           currency: "USD",
           fx_rate_at_execution: 17.30,
           executed_at: 1.day.ago)
  end

  describe "Position (native USD methods — unchanged from before #57)" do
    it "Position#avg_cost is the USD weighted avg" do
      expect(position.avg_cost).to eq(155.0)
    end

    it "Position#market_value returns shares × current_price in USD (native)" do
      expect(position.market_value).to eq(3_100.0)  # 20 × 155
    end

    it "Position#total_gain returns gain in USD (zero because price matched avg)" do
      expect(position.total_gain).to eq(0.0)  # 20 × (155 - 155)
    end

    it "Position#total_gain_percent is currency-agnostic (zero)" do
      expect(position.total_gain_percent).to eq(0)
    end
  end

  describe "Position (currency-aware methods — #57 era)" do
    it "Position#avg_cost_in('MXN') derives from each trade's historical FX" do
      # (10 × 150 × 17.05) + (10 × 160 × 17.30) = 25,575 + 27,680 = 53,255 MXN total cost
      # 53,255 / 20 shares = 2,662.75 MXN/share
      expect(position.avg_cost_in("MXN").to_f).to be_within(0.01).of(2_662.75)
    end

    it "Position#cost_basis_in('MXN') = shares × avg_cost_in" do
      expect(position.cost_basis_in("MXN").to_f).to be_within(0.01).of(53_255.0)
    end

    it "Position#avg_cost_in('USD') returns the native avg_cost" do
      # When target == asset.currency, returns raw avg_cost
      expect(position.avg_cost_in("USD").to_f).to eq(155.0)
    end
  end

  describe "Portfolio aggregate methods (must be currency-aware)" do
    subject(:p) { portfolio.reload }

    it "Portfolio#invested_value(currency: 'MXN') = 20 × 155 × 17.50 = 54,250 MXN" do
      expect(p.invested_value(currency: "MXN").to_f).to be_within(0.01).of(54_250.0)
    end

    it "Portfolio#total_value(currency: 'MXN') = invested + buying_power(0) = 54,250 MXN" do
      expect(p.total_value(currency: "MXN").to_f).to be_within(0.01).of(54_250.0)
    end

    it "Portfolio#total_unrealized_gain(currency: 'MXN') = 54,250 - 53,255 = 995 MXN" do
      # Critical: USD-side shows 0 gain, but MXN-side shows 995 because peso weakened.
      # If this returns 0, the calculator is using `total_gain` (native) instead of
      # cost_basis_in(currency) — the bug #57 was meant to fix.
      expect(p.total_unrealized_gain(currency: "MXN").to_f).to be_within(0.01).of(995.0)
    end

    it "Portfolio#allocation_by_asset_type(currency: 'MXN') for stocks = 54,250 MXN" do
      result = p.allocation_by_asset_type(currency: "MXN")
      expect(result["stock"].to_f).to be_within(0.01).of(54_250.0)
    end
  end

  describe "PortfolioSummary (driven by user.preferred_currency = MXN)" do
    subject(:summary) { Trading::Domain::PortfolioSummary.new(portfolio) }

    it "uses MXN as the active currency" do
      expect(summary.currency).to eq("MXN")
    end

    it "#total_value = 54,250 MXN" do
      expect(summary.total_value.to_f).to be_within(0.01).of(54_250.0)
    end

    it "#total_invested = 53,255 MXN" do
      expect(summary.total_invested.to_f).to be_within(0.01).of(53_255.0)
    end

    it "#unrealized_gain.absolute = 995 MXN" do
      expect(summary.unrealized_gain.absolute).to be_within(0.01).of(995.0)
    end

    it "#unrealized_gain.percent ≈ 1.87%" do
      expect(summary.unrealized_gain.percent).to be_within(0.01).of(1.87)
    end
  end

  describe "Snapshot-based calculators (day_gain, period_returns) with cross-currency snapshots" do
    let!(:yesterday_snap_in_usd) do
      # Yesterday's snapshot was recorded in USD-terms (e.g., user was USD-preferred
      # at that time). Today the user is MXN-preferred. The day_gain calculator
      # must convert yesterday's USD value to MXN using today's FX before diffing.
      create(:portfolio_snapshot,
             portfolio: portfolio,
             date: Date.yesterday,
             total_value: 3_000.0,       # USD value
             cash_value: 0,
             invested_value: 3_000.0,
             currency: "USD")
    end

    it "PortfolioSummary#day_gain converts yesterday's USD snapshot to MXN before diffing" do
      summary = Trading::Domain::PortfolioSummary.new(portfolio)
      # Today: 54,250 MXN. Yesterday (USD 3,000 × 17.50 FX): 52,500 MXN.
      # Diff: +1,750 MXN.
      expect(summary.day_gain.absolute).to be_within(0.01).of(1_750.0)
      # Percent: 1,750 / 52,500 = ~3.33%
      expect(summary.day_gain.percent).to be_within(0.01).of(3.33)
    end

    it "PeriodReturnsCalculator#calculate works with mixed-currency snapshots" do
      # Add older snapshots that were recorded in different currencies over time
      create(:portfolio_snapshot, portfolio: portfolio, date: 7.days.ago,
             total_value: 50_000.0, cash_value: 0, invested_value: 50_000.0, currency: "MXN")
      create(:portfolio_snapshot, portfolio: portfolio, date: 30.days.ago,
             total_value: 2_800.0, cash_value: 0, invested_value: 2_800.0, currency: "USD")

      result = Trading::Domain::PeriodReturnsCalculator.new(portfolio).calculate
      # 7-day baseline (MXN 50,000) → today 54,250 MXN → gain 4,250 / 50,000 = 8.5%
      expect(result["1W"].percent).to be_within(0.01).of(8.5)
      # 30-day baseline (USD 2,800 × 17.50 = 49,000 MXN) → today 54,250 → 5,250 / 49,000 ≈ 10.71%
      expect(result["1M"].percent).to be_within(0.01).of(10.71)
    end
  end

  describe "WeeklyInsightCalculator (snapshot-based) — currency neutrality check" do
    it "computes weekly_change correctly when snapshots are same-currency" do
      # WeeklyInsightCalculator only cares about the percentage change between
      # the first and last snapshot. If snapshots are in different currencies,
      # the % is meaningless — but the calculator itself doesn't convert.
      # Caller responsibility: pass same-currency snapshots.
      snap_old = double("snapshot", total_value: 100_000.0)
      snap_new = double("snapshot", total_value: 110_000.0)
      result = Trading::Domain::WeeklyInsightCalculator.calculate(
        snapshots: [ snap_old, snap_new ],
        positions: []
      )
      expect(result[:weekly_change]).to eq(10.0)
    end
  end

  describe "Inverse asymmetry check (USD-preferred user same scenario)" do
    let(:usd_user)      { create(:user, preferred_currency: "USD") }
    let(:usd_portfolio) { create(:portfolio, user: usd_user, buying_power: 0) }
    let!(:usd_position) do
      create(:position, portfolio: usd_portfolio, asset: asset, shares: 20, avg_cost: 155.0, status: :open).tap do |pos|
        create(:trade, portfolio: usd_portfolio, asset: asset, position: pos, side: :buy,
                       shares: 10, price_per_share: 150.0, total_amount: 1_500.0,
                       currency: "USD", fx_rate_at_execution: 17.05, executed_at: 2.days.ago)
        create(:trade, portfolio: usd_portfolio, asset: asset, position: pos, side: :buy,
                       shares: 10, price_per_share: 160.0, total_amount: 1_600.0,
                       currency: "USD", fx_rate_at_execution: 17.30, executed_at: 1.day.ago)
      end
    end

    it "USD-preferred user sees gain = 0 (price hasn't moved on USD weighted-avg)" do
      summary = Trading::Domain::PortfolioSummary.new(usd_portfolio)
      expect(summary.unrealized_gain.absolute).to be_within(0.01).of(0.0)
    end

    it "MXN-preferred user sees +995 MXN on the same trades (FX-on-principal effect)" do
      # Both portfolios bought the same shares at the same prices and FXs.
      # The accounting difference comes purely from which currency the user
      # measures wealth in. Lucía's test of intellectual honesty for the
      # calculator: this number MUST differ from zero for an MXN user.
      summary = Trading::Domain::PortfolioSummary.new(portfolio)
      expect(summary.unrealized_gain.absolute).to be_within(0.01).of(995.0)
    end
  end
end
