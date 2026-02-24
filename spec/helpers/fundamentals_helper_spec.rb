require "rails_helper"

RSpec.describe FundamentalsHelper, type: :helper do
  describe "#format_metric_value" do
    it "returns em dash for nil values" do
      expect(helper.format_metric_value(nil, :ratio)).to eq("—")
    end

    it "formats ratios with 2 decimal places" do
      expect(helper.format_metric_value(28.5, :ratio)).to eq("28.50")
    end

    it "formats percentages with 1 decimal place and % suffix" do
      expect(helper.format_metric_value(24.6, :percentage)).to eq("24.6%")
    end

    it "formats text values as strings" do
      expect(helper.format_metric_value("Technology", :text)).to eq("Technology")
    end

    it "formats large numbers with delimiter" do
      expect(helper.format_metric_value(15_000_000, :number)).to eq("15,000,000")
    end
  end

  describe "#format_large_currency" do
    it "formats trillions" do
      expect(helper.format_large_currency(3_230_000_000_000)).to eq("$3.23T")
    end

    it "formats billions" do
      expect(helper.format_large_currency(107_300_000_000)).to eq("$107.3B")
    end

    it "formats millions" do
      expect(helper.format_large_currency(5_400_000)).to eq("$5.4M")
    end

    it "formats small values as currency" do
      expect(helper.format_large_currency(6.07)).to eq("$6.07")
    end
  end

  describe "#gaap_label" do
    it "returns US GAAP for US assets" do
      asset = build(:asset, country: "US")
      expect(helper.gaap_label(asset)).to eq("US GAAP")
    end

    it "returns As reported for non-US assets" do
      asset = build(:asset, country: "MX")
      expect(helper.gaap_label(asset)).to eq("As reported")
    end
  end
end
