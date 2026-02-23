require "rails_helper"

RSpec.describe MarketIndex, type: :model do
  subject(:index) { build(:market_index) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires name" do
      index.name = nil
      expect(index).not_to be_valid
    end

    it "requires symbol" do
      index.symbol = nil
      expect(index).not_to be_valid
    end

    it "requires unique symbol" do
      create(:market_index, symbol: "SPX")
      index.symbol = "SPX"
      expect(index).not_to be_valid
    end
  end

  describe "scopes" do
    it ".major returns predefined major indices including IPC" do
      spx = create(:market_index, symbol: "SPX", name: "S&P 500")
      ndx = create(:market_index, symbol: "NDX", name: "NASDAQ 100")
      ipc = create(:market_index, symbol: "IPC", name: "IPC Mexico")
      other = create(:market_index, symbol: "NIKKEI", name: "Nikkei 225")
      expect(MarketIndex.major).to contain_exactly(spx, ndx, ipc)
    end
  end

  describe ".vix" do
    it "returns the VIX index" do
      vix = create(:market_index, symbol: "VIX", name: "CBOE Volatility")
      expect(MarketIndex.vix).to eq(vix)
    end

    it "returns nil when VIX does not exist" do
      expect(MarketIndex.vix).to be_nil
    end
  end

  describe "defaults" do
    it "has is_open false by default" do
      idx = MarketIndex.new
      expect(idx.is_open).to be false
    end
  end
end
