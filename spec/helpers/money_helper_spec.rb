require "rails_helper"

RSpec.describe MoneyHelper do
  describe "#format_currency_mx" do
    it "formats with ISO code prefix and grouped digits" do
      expect(helper.format_currency_mx(1_247_580.40, currency: "MXN")).to eq("MXN 1,247,580.40")
    end

    it "respects custom precision (CETES yields use 4)" do
      expect(helper.format_currency_mx(10.1234, currency: "MXN", precision: 4)).to eq("MXN 10.1234")
    end

    it "respects integer precision for round amounts" do
      expect(helper.format_currency_mx(180_000, currency: "MXN", precision: 0)).to eq("MXN 180,000")
    end

    it "handles nil amount as 0.00" do
      expect(helper.format_currency_mx(nil, currency: "MXN")).to eq("MXN 0.00")
    end

    it "formats USD the same way" do
      expect(helper.format_currency_mx(2500.75, currency: "USD")).to eq("USD 2,500.75")
    end
  end

  describe "#format_shares" do
    it "drops the decimals a whole holding does not need" do
      expect(helper.format_shares(1_200)).to eq("1,200")
    end

    it "keeps four decimals when the holding is fractional" do
      expect(helper.format_shares(0.4523)).to eq("0.4523")
    end

    it "groups the thousands, which three screens used to omit" do
      expect(helper.format_shares(1234.5678)).to eq("1,234.5678")
    end

    it "does not round a fractional position down to nothing" do
      expect(helper.format_shares(BigDecimal("0.4"))).to eq("0.4000")
    end
  end
end
