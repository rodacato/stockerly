require "rails_helper"

RSpec.describe Trading::Domain::ExecutionRate do
  let(:on) { Date.new(2025, 12, 8) }
  let(:usd_asset) { create(:asset, symbol: "VT", currency: "USD") }
  let(:mxn_asset) { create(:asset, :mexican, symbol: "WALMEX.MX") }

  before { FxRateHistory.record(base: "USD", quote: "MXN", date: on, rate: 18.2293, source: "banxico") }

  def trade_for(asset, currency:, rate:)
    create(:trade, asset: asset, currency: currency, fx_rate_at_execution: rate, executed_at: on.noon)
  end

  # The whole matrix, because the bug this replaced was one cell of it being
  # silently wrong while the other three looked fine.
  describe ".multiplier" do
    it "is 1 when the target is the trade's own currency" do
      trade = trade_for(usd_asset, currency: "USD", rate: 18.2293)

      expect(described_class.multiplier(trade: trade, target: "USD")).to eq(1)
    end

    it "is the stored rate when the target is the reference" do
      trade = trade_for(usd_asset, currency: "USD", rate: 18.2293)

      expect(described_class.multiplier(trade: trade, target: "MXN")).to eq(BigDecimal("18.2293"))
    end

    it "is 1 for a peso trade read in pesos" do
      trade = trade_for(mxn_asset, currency: "MXN", rate: 1)

      expect(described_class.multiplier(trade: trade, target: "MXN")).to eq(1)
    end

    # The cell that used to be wrong: a peso trade stored 1.0 and was then read
    # in USD as if one peso were one dollar.
    it "inverts the day's FIX for a peso trade read in dollars" do
      trade = trade_for(mxn_asset, currency: "MXN", rate: 1)

      expect(described_class.multiplier(trade: trade, target: "USD").round(8))
        .to eq((BigDecimal(1) / BigDecimal("18.2293")).round(8))
    end

    it "uses the rate of the day the trade executed, not today's" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: Date.current, rate: 25.0, source: "banxico")
      trade = trade_for(mxn_asset, currency: "MXN", rate: 1)

      expect(described_class.multiplier(trade: trade, target: "USD").round(4)).to eq(BigDecimal("0.0549"))
    end

    it "fails loud rather than valuing a null rate at 1:1" do
      trade = trade_for(usd_asset, currency: "USD", rate: nil)

      expect { described_class.multiplier(trade: trade, target: "MXN") }
        .to raise_error(Trading::Domain::MissingFxRate, /no rate captured/)
    end

    it "fails loud when the target has no rate on that day" do
      FxRateHistory.delete_all
      trade = trade_for(mxn_asset, currency: "MXN", rate: 1)

      expect { described_class.multiplier(trade: trade, target: "USD") }
        .to raise_error(Trading::Domain::MissingFxRate, /No USD->MXN rate/)
    end
  end

  describe ".capture" do
    it "is 1 for a trade already in the reference currency" do
      expect(described_class.capture(currency: "MXN", at_date: on)).to eq(1)
    end

    it "reads the FIX of the trade's own date" do
      expect(described_class.capture(currency: "USD", at_date: on)).to eq(BigDecimal("18.2293"))
    end

    it "prefers an explicit override over the series" do
      expect(described_class.capture(currency: "USD", at_date: on, override: BigDecimal("17.5"))).to eq(BigDecimal("17.5"))
    end

    it "returns nothing when the series cannot answer, so the caller decides" do
      FxRateHistory.delete_all

      expect(described_class.capture(currency: "USD", at_date: on)).to be_nil
    end
  end
end
