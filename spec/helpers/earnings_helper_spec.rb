require "rails_helper"

RSpec.describe EarningsHelper, type: :helper do
  let(:asset)   { build(:asset, :stock, symbol: "WALMEX.MX", exchange: "BMV", currency: "MXN") }
  let(:us_asset) { build(:asset, :stock, symbol: "AAPL", exchange: "NASDAQ", currency: "USD") }

  describe "#earnings_date_header" do
    it "formats the date in es-MX with full weekday + ABBR month" do
      expect(helper.earnings_date_header(Date.new(2026, 5, 19))).to eq("Martes · 19 MAY 2026")
    end
  end

  describe "#earnings_period_label" do
    it "returns NTYY for Q2 2026" do
      event = build(:earnings_event, report_date: Date.new(2026, 5, 19))
      expect(helper.earnings_period_label(event)).to eq("2T26")
    end
  end

  describe "#earnings_timing_label" do
    it "returns 'pre-apertura' for before_market_open" do
      event = build(:earnings_event, timing: :before_market_open)
      expect(helper.earnings_timing_label(event)).to eq("pre-apertura")
    end

    it "returns 'cierre de mercado' for after_market_close" do
      event = build(:earnings_event, timing: :after_market_close)
      expect(helper.earnings_timing_label(event)).to eq("cierre de mercado")
    end
  end

  describe "#earnings_status_label" do
    it "returns 'Reportado' when actual_eps is present" do
      event = build(:earnings_event, actual_eps: 1.5)
      expect(helper.earnings_status_label(event)).to eq("Reportado")
    end

    it "returns 'Por reportar' when actual_eps is nil" do
      event = build(:earnings_event, actual_eps: nil)
      expect(helper.earnings_status_label(event)).to eq("Por reportar")
    end
  end

  describe "#earnings_currency" do
    it "returns the asset's currency when present" do
      event = build(:earnings_event, asset: asset)
      expect(helper.earnings_currency(event)).to eq("MXN")
    end
  end

  describe "#earnings_venue" do
    it "returns the asset's exchange" do
      event = build(:earnings_event, asset: us_asset)
      expect(helper.earnings_venue(event)).to eq("NASDAQ")
    end
  end

  describe "#earnings_delta_classes" do
    it "returns positive classes for >= 0" do
      expect(helper.earnings_delta_classes(0)).to include("emerald")
      expect(helper.earnings_delta_classes(5.5)).to include("emerald")
    end

    it "returns negative classes for < 0" do
      expect(helper.earnings_delta_classes(-3.2)).to include("rose")
    end

    it "returns muted classes for nil" do
      expect(helper.earnings_delta_classes(nil)).to include("slate")
    end
  end
end
