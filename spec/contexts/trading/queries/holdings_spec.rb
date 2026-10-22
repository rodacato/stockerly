require "rails_helper"

# ADR-031's 2026-10-22 amendment: the assistant reads the owner's holdings as
# Activos values them, so the figures here are PositionBreakdown's, not new ones.
RSpec.describe Trading::Queries::Holdings do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  def hold(symbol, shares:, avg_cost:, price:, rate:)
    asset = create(:asset, :stock, symbol: symbol, currency: "USD", current_price: price, price_updated_at: Time.current)
    position = create(:position, portfolio: portfolio, asset: asset, shares: shares, avg_cost: avg_cost, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy, shares: shares, price_per_share: avg_cost,
                   currency: "USD", fx_rate_at_execution: rate, executed_at: 30.days.ago)
    position
  end

  context "with a USD position for an MXN investor" do
    # Bought 10 @ USD 100 at 17 → cost 17,000 MXN; today USD 120 at 20 → 24,000 MXN.
    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
      hold("AAPL", shares: 10, avg_cost: 100, price: 120, rate: 17.0)
    end

    it "states the screen's figures in the owner's currency, split into asset and exchange rate" do
      position = described_class.call(user: user)[:positions].sole

      expect(position).to include(symbol: "AAPL", value: 24_000, cost: 17_000, gain: 7_000, from_asset: 4_000, from_fx: 3_000,
                                  share_percent: 100.0)
      expect(position[:gain_percent]).to be_within(0.01).of(41.18)
    end

    it "totals what the portfolio summary totals" do
      data = described_class.call(user: user)

      expect(data[:currency]).to eq("MXN")
      expect(data[:total]).to include(value: 24_000, cost: 17_000, gain: 7_000)
      expect(data[:total][:day_gain]).to be_nil
    end

    it "crosses the boundary as plain data" do
      values = described_class.call(user: user)[:positions].flat_map(&:values)

      expect(values.grep(ActiveRecord::Base)).to be_empty
    end

    it "lists the largest holding first" do
      hold("MSFT", shares: 100, avg_cost: 100, price: 120, rate: 17.0)

      expect(described_class.call(user: user)[:positions].pluck(:symbol)).to eq(%w[MSFT AAPL])
    end
  end

  it "has nothing to say about a portfolio with nothing open" do
    portfolio

    expect(described_class.call(user: user)).to be_nil
  end

  it "says nothing rather than a partial total when a rate is missing" do
    hold("AAPL", shares: 10, avg_cost: 100, price: 120, rate: 17.0)

    expect(described_class.call(user: user)).to be_nil
  end

  it "reads the one owner when no user is given" do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
    hold("AAPL", shares: 10, avg_cost: 100, price: 120, rate: 17.0)

    expect(described_class.call[:positions].pluck(:symbol)).to eq(%w[AAPL])
  end
end
