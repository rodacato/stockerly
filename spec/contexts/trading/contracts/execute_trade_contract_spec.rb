require "rails_helper"

RSpec.describe Trading::Contracts::ExecuteTradeContract do
  subject(:contract) { described_class.new }

  let!(:asset) { create(:asset, symbol: "AAPL") }

  let(:valid_params) do
    {
      asset_symbol: "AAPL",
      side: "buy",
      shares: 10.0,
      price_per_share: 150.0
    }
  end

  describe "valid params" do
    it "accepts valid buy params" do
      result = contract.call(valid_params)
      expect(result).to be_success
    end

    it "accepts valid sell params" do
      result = contract.call(valid_params.merge(side: "sell"))
      expect(result).to be_success
    end
  end

  describe "required fields" do
    it "fails when asset_symbol is missing" do
      result = contract.call(valid_params.except(:asset_symbol))
      expect(result.errors[:asset_symbol]).to be_present
    end

    it "fails when side is invalid" do
      result = contract.call(valid_params.merge(side: "hold"))
      expect(result.errors[:side]).to be_present
    end
  end

  describe "numeric validations" do
    it "fails when shares is zero or negative" do
      result = contract.call(valid_params.merge(shares: 0.0))
      expect(result.errors[:shares]).to include("must be greater than 0")
    end

    it "fails when price_per_share is zero or negative" do
      result = contract.call(valid_params.merge(price_per_share: -5.0))
      expect(result.errors[:price_per_share]).to include("must be greater than 0")
    end
  end

  describe "asset existence" do
    it "fails when asset_symbol does not exist" do
      result = contract.call(valid_params.merge(asset_symbol: "ZZZZ"))
      expect(result.errors[:asset_symbol]).to include("asset not found")
    end
  end

  describe "maturity_date (fixed-income only, #29 JTBD #3)" do
    let!(:cetes_asset) { create(:asset, :fixed_income, symbol: "CETES_28D") }

    let(:cetes_params) do
      {
        asset_symbol: "CETES_28D",
        side: "buy",
        shares: 100.0,
        price_per_share: 9.85
      }
    end

    it "requires maturity_date for fixed_income assets" do
      result = contract.call(cetes_params)
      expect(result.errors[:maturity_date]).to include("required for fixed-income assets")
    end

    it "accepts a future maturity_date for fixed_income" do
      result = contract.call(cetes_params.merge(maturity_date: 28.days.from_now.to_date.iso8601))
      expect(result).to be_success
    end

    it "rejects a past maturity_date" do
      result = contract.call(cetes_params.merge(maturity_date: 1.day.ago.to_date.iso8601))
      expect(result.errors[:maturity_date]).to include("must be in the future")
    end

    it "rejects today as maturity_date (must be strictly future)" do
      result = contract.call(cetes_params.merge(maturity_date: Date.current.iso8601))
      expect(result.errors[:maturity_date]).to include("must be in the future")
    end

    it "rejects malformed maturity_date strings" do
      result = contract.call(cetes_params.merge(maturity_date: "not-a-date"))
      expect(result.errors[:maturity_date]).to include("must be a valid date")
    end

    it "does NOT require maturity_date for non-fixed-income assets" do
      # `asset` (top of file) is a stock — valid_params already proves this; this
      # spec pins the behavior so a future contract change can't silently start
      # requiring maturity_date for stocks/crypto/etf.
      result = contract.call(valid_params)
      expect(result).to be_success
      expect(result.errors[:maturity_date]).to be_nil
    end

    it "ignores maturity_date when supplied for a non-fixed-income asset" do
      # If a client accidentally sends maturity_date for a stock trade, the
      # contract should pass it through (the use case ignores it for non-fixed-
      # income positions in the next commit).
      result = contract.call(valid_params.merge(maturity_date: 28.days.from_now.to_date.iso8601))
      expect(result).to be_success
    end
  end
end
