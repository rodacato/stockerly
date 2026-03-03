require "rails_helper"

RSpec.describe MarketData::Domain::YieldCalculator do
  describe ".discount_price" do
    it "calculates correctly for 28-day CETES at 11.15% yield" do
      price = described_class.discount_price(face_value: 10.0, annual_yield: 11.15, days: 28)

      # P = 10 / (1 + 0.1115 * 28/360) = 10 / 1.008672... ≈ 9.914027
      expect(price).to be_within(0.001).of(9.914)
    end

    it "returns face value when days is 0" do
      price = described_class.discount_price(face_value: 10.0, annual_yield: 11.15, days: 0)

      expect(price).to eq(10.0.to_d)
    end
  end

  describe ".yield_to_maturity" do
    it "calculates correctly from known price" do
      # Given: purchase_price ≈ 9.914, face_value = 10, days = 28
      ytm = described_class.yield_to_maturity(purchase_price: 9.914, face_value: 10.0, days: 28)

      # YTM = ((10 - 9.914) / 9.914) * (360/28) * 100 ≈ 11.15%
      expect(ytm).to be_within(0.15).of(11.15)
    end

    it "returns 0 when purchase_price equals face_value" do
      ytm = described_class.yield_to_maturity(purchase_price: 10.0, face_value: 10.0, days: 28)

      expect(ytm).to eq(0)
    end
  end

  describe ".total_return" do
    it "calculates gain for given quantity" do
      gain = described_class.total_return(face_value: 10.0, purchase_price: 9.914, quantity: 1000)

      # (10.0 - 9.914) * 1000 = 86.0
      expect(gain).to eq(86.0.to_d)
    end
  end

  describe ".investment_value" do
    it "returns face_value times quantity" do
      value = described_class.investment_value(face_value: 10.0, quantity: 1000)

      expect(value).to eq(10_000.0.to_d)
    end
  end
end
