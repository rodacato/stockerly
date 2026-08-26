require "rails_helper"

RSpec.describe FundamentalsHelper, type: :helper do
  describe "#format_metric_value" do
    # Every producer stores a percentage as a decimal ratio. Printing it raw
    # showed Apple's 24.6% net margin as "0.2%".
    it "scales a decimal ratio into a percentage" do
      expect(helper.format_metric_value(0.2461, :percentage)).to eq("24.6%")
    end

    it "scales a ratio above 1.0, which ROE routinely is" do
      expect(helper.format_metric_value(1.57, :percentage)).to eq("157.0%")
    end

    it "leaves a :ratio metric unscaled" do
      expect(helper.format_metric_value(1.42, :ratio)).to eq("1.42")
    end

    it "renders a dash for a missing value instead of 0%" do
      expect(helper.format_metric_value(nil, :percentage)).to eq("—")
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
