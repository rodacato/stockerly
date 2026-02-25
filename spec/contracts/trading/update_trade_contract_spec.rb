require "rails_helper"

RSpec.describe Trading::UpdateTradeContract do
  subject(:contract) { described_class.new }

  let!(:asset) { create(:asset, symbol: "AAPL") }
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:trade) do
    create(:trade, portfolio: portfolio, asset: asset,
           side: :buy, shares: 10.0, price_per_share: 150.0,
           total_amount: 1500.0, executed_at: Time.current)
  end

  describe "valid params" do
    it "accepts trade_id with shares update" do
      result = contract.call(trade_id: trade.id, shares: 15.0)
      expect(result).to be_success
    end

    it "accepts trade_id with price update" do
      result = contract.call(trade_id: trade.id, price_per_share: 160.0)
      expect(result).to be_success
    end

    it "accepts trade_id with fee update" do
      result = contract.call(trade_id: trade.id, fee: 9.99)
      expect(result).to be_success
    end
  end

  describe "required fields" do
    it "fails when trade_id is missing" do
      result = contract.call(shares: 10.0)
      expect(result.errors[:trade_id]).to be_present
    end

    it "fails when trade does not exist" do
      result = contract.call(trade_id: 999999, shares: 10.0)
      expect(result.errors[:trade_id]).to include("trade not found")
    end
  end

  describe "numeric validations" do
    it "fails when shares is zero or negative" do
      result = contract.call(trade_id: trade.id, shares: 0.0)
      expect(result.errors[:shares]).to include("must be greater than 0")
    end

    it "fails when price_per_share is zero or negative" do
      result = contract.call(trade_id: trade.id, price_per_share: -5.0)
      expect(result.errors[:price_per_share]).to include("must be greater than 0")
    end
  end
end
