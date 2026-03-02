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
end
