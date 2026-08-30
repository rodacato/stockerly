require "rails_helper"

RSpec.describe FundamentalsHelper, type: :helper do
  describe "#format_metric_value" do
    # Every producer stores a percentage as a decimal ratio. Printing it raw
    # showed Apple's 24.6% net margin as "0.2%".
    it "scales a decimal ratio into a percentage" do
      expect(helper.format_metric_value(0.2461, :percentage, currency: "USD")).to eq("24.6%")
    end

    it "scales a ratio above 1.0, which ROE routinely is" do
      expect(helper.format_metric_value(1.57, :percentage, currency: "USD")).to eq("157.0%")
    end

    it "leaves a :ratio metric unscaled" do
      expect(helper.format_metric_value(1.42, :ratio, currency: "USD")).to eq("1.42")
    end

    it "renders a dash for a missing value instead of 0%" do
      expect(helper.format_metric_value(nil, :percentage, currency: "USD")).to eq("—")
    end
  end

  describe "#metric_chip" do
    def defn(key) = MarketData::Domain::MetricDefinitions.find(key)

    it "calls a beta above 1.3 volatile" do
      expect(helper.metric_chip(defn(:beta), 1.42).first).to eq(I18n.t("market.chips.volatil"))
    end

    it "calls a beta below 0.7 defensive" do
      expect(helper.metric_chip(defn(:beta), 0.55).first).to eq(I18n.t("market.chips.defensivo"))
    end

    it "flags a payout above 1.0, which is a ratio and not a percentage" do
      expect(helper.metric_chip(defn(:payout_ratio), 1.12).first).to eq(I18n.t("market.chips.sobre_utilidades"))
    end

    it "does not flag a payout below 1.0" do
      expect(helper.metric_chip(defn(:payout_ratio), 0.4)).to be_nil
    end

    # D36: a chip is only built where the threshold is definitional. Net margin
    # varies by industry, so inventing one would read as analysis and be a guess.
    it "builds no chip for a metric whose threshold varies by industry" do
      expect(helper.metric_chip(defn(:net_margin), 0.26)).to be_nil
    end

    it "builds no chip for a missing value" do
      expect(helper.metric_chip(defn(:beta), nil)).to be_nil
    end
  end
end

RSpec.describe FundamentalsHelper, "#remaining_metrics_by_category", type: :helper do
  def presenter_for(asset, metrics)
    MarketData::Domain::FundamentalPresenter.new(
      asset: asset, fundamental: build(:asset_fundamental, metrics: metrics)
    )
  end

  it "never offers crypto categories on an equity" do
    asset = build(:asset, :stock, current_price: 100)
    rest = helper.remaining_metrics_by_category(asset, presenter_for(asset, "circulating_supply" => "19000000"))

    expect(rest).not_to have_key(:crypto_market)
  end

  it "never offers dividend categories on a crypto asset" do
    asset = build(:asset, :crypto, current_price: 100)
    rest = helper.remaining_metrics_by_category(asset, presenter_for(asset, "dividend_yield" => "0.02"))

    expect(rest).not_to have_key(:dividends)
  end

  # Twenty cards reading "—" is not depth. A metric no producer filled is left out.
  it "drops a metric with no value rather than rendering an empty card" do
    asset = build(:asset, :stock, current_price: 100)
    rest = helper.remaining_metrics_by_category(asset, presenter_for(asset, "gross_margin" => "0.46"))

    expect(rest[:profitability].map(&:key)).to eq([ :gross_margin ])
  end

  it "leaves out what the extract already shows" do
    asset = build(:asset, :stock, current_price: 100)
    presenter = presenter_for(asset, "profit_margin" => "0.21", "forward_pe" => "28.4")
    rest = helper.remaining_metrics_by_category(asset, presenter)

    expect(rest.values.flatten.map(&:key)).to include(:forward_pe)
    expect(rest.values.flatten.map(&:key)).not_to include(:net_margin)
  end

  # The five are named, not counted: a spec that only checked the size would go
  # on passing through any swap, which is the change most worth catching.
  it "shows five metrics, and they are the five that answer a question out loud" do
    expect(FundamentalsHelper::SUMMARY_METRICS)
      .to eq(%i[pe_ratio net_margin revenue_growth debt_to_equity dividend_yield])
  end
end
