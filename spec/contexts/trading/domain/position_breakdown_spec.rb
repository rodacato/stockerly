require "rails_helper"

RSpec.describe Trading::Domain::PositionBreakdown do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  def usd_position(shares:, avg_cost:, price:, bought_at_rate:)
    asset = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: price)
    position = create(:position, portfolio: portfolio, asset: asset, shares: shares,
                                 avg_cost: avg_cost, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy,
                   shares: shares, price_per_share: avg_cost, currency: "USD",
                   fx_rate_at_execution: bought_at_rate, executed_at: 30.days.ago)
    position
  end

  def breakdown(position) = described_class.new(position.reload, currency: "MXN")

  describe "a USD position for an MXN investor" do
    # Bought 10 @ USD 100 when the rate was 17 → cost 17,000 MXN.
    # Today the asset is USD 120 and the rate is 20 → value 24,000 MXN.
    before { create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0) }

    let(:position) { usd_position(shares: 10, avg_cost: 100, price: 120, bought_at_rate: 17.0) }

    it "reports the total gain in the investor's currency" do
      expect(breakdown(position).total.amount).to eq(7_000)
    end

    it "attributes the asset's move at today's rate" do
      # 10 × (120 − 100) × 20 = 4,000
      expect(breakdown(position).from_asset.amount).to eq(4_000)
    end

    it "attributes what the peso did to the money already committed" do
      # 10 × 100 × 20 − 17,000 = 3,000
      expect(breakdown(position).from_fx.amount).to eq(3_000)
    end

    # The whole point: the parts must reconstruct the total, or the split is
    # decoration rather than an explanation.
    it "splits the total exactly, with nothing left over" do
      b = breakdown(position)

      expect(b.from_asset.amount + b.from_fx.amount).to eq(b.total.amount)
    end

    it "states each part as a percentage of what it actually cost" do
      b = breakdown(position)

      expect(b.total.percent).to be_within(0.01).of(41.18)
      expect(b.from_asset.percent).to be_within(0.01).of(23.53)
      expect(b.from_fx.percent).to be_within(0.01).of(17.65)
    end
  end

  # The currency can eat a gain the asset made. That is the case the split
  # exists to make visible.
  it "shows a peso that took back what the asset gave" do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 15.0)
    position = usd_position(shares: 10, avg_cost: 100, price: 120, bought_at_rate: 20.0)

    b = breakdown(position)

    expect(b.from_asset.amount).to eq(3_000)
    expect(b.from_fx.amount).to eq(-5_000)
    expect(b.total.amount).to eq(-2_000)
  end

  describe "a position in the investor's own currency" do
    it "has no currency story to tell" do
      asset = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70)
      position = create(:position, portfolio: portfolio, asset: asset, shares: 100,
                                   avg_cost: 60, status: :open)
      create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy,
                     shares: 100, price_per_share: 60, currency: "MXN", executed_at: 10.days.ago)

      b = breakdown(position)

      expect(b.same_currency?).to be(true)
      expect(b.from_fx.amount).to eq(0)
      expect(b.from_asset.amount).to eq(b.total.amount)
    end
  end

  it "reports zero percent rather than dividing by a cost basis of nothing" do
    asset = create(:asset, :stock, symbol: "FREE", currency: "MXN", current_price: 10)
    position = create(:position, portfolio: portfolio, asset: asset, shares: 0,
                                 avg_cost: 10, status: :open)

    expect(breakdown(position).total.percent).to eq(0)
  end
  # The SIC settles a US-listed asset in pesos, so one position can hold buys
  # paid in two currencies. Both legs below cost USD 100/share.
  describe "a USD position with one leg settled in pesos" do
    let(:bought_on) { 30.days.ago.to_date }

    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
      FxRateHistory.record(base: "USD", quote: "MXN", date: bought_on, rate: 17.0, source: "test")
    end

    let(:position) do
      asset = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 120)
      pos = create(:position, portfolio: portfolio, asset: asset, shares: 20, avg_cost: 100, status: :open)

      create(:trade, portfolio: portfolio, position: pos, asset: asset, side: :buy,
                     shares: 10, price_per_share: 100, currency: "USD",
                     fx_rate_at_execution: 17.0, executed_at: bought_on)
      create(:trade, portfolio: portfolio, position: pos, asset: asset, side: :buy,
                     shares: 10, price_per_share: 1_700, currency: "MXN",
                     fx_rate_at_execution: 1.0, executed_at: bought_on)

      pos.recalculate_avg_cost!
      pos
    end

    it "averages both legs in the asset's currency" do
      expect(position.reload.avg_cost.to_f).to be_within(0.01).of(100.0)
    end

    it "attributes the asset's move without the peso leg distorting it" do
      expect(breakdown(position).from_asset.amount).to eq(8_000)
    end

    it "still splits into two parts that sum to the total" do
      split = breakdown(position)

      expect(split.from_asset.amount + split.from_fx.amount).to eq(split.total.amount)
    end
  end
end
