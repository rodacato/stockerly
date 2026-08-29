require "rails_helper"

RSpec.describe MarketData::Queries::AssetMarketContext do
  def context_for(asset, day_change: nil) = described_class.call(asset: asset, day_change: day_change)

  describe "the reference index" do
    it "reads a Mexican asset against the IPC" do
      create(:market_index, symbol: "IPC", name: "IPC", change_percent: 0.4)
      asset = create(:asset, :mexican)

      expect(context_for(asset)[:index].symbol).to eq("IPC")
    end

    it "reads a US asset against the S&P 500" do
      create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: 0.4)
      asset = create(:asset, :stock, country: "US")

      expect(context_for(asset)[:index].symbol).to eq("SPX")
    end

    # Crypto trades against no index, so it gets none rather than a misleading one.
    it "gives a crypto asset no index at all" do
      create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: 0.4)

      expect(context_for(create(:asset, :crypto))[:index]).to be_nil
    end
  end

  describe "the divergence reading" do
    let!(:index) { create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: -3.0) }

    def divergence(asset_change)
      context_for(create(:asset, :stock, country: "US"), day_change: asset_change)[:divergence]
    end

    # The artboard's own example: the index fell further than the asset, so the
    # day says more about the market. The threshold is calibrated to agree.
    it "calls the artboard's -3.0 index against -2.1 asset market-led" do
      expect(divergence(-2.1)).to eq(:market_led)
    end

    it "calls a bigger asset move asset-led" do
      expect(divergence(-8.0)).to eq(:asset_led)
    end

    it "calls a move against the index asset-led, however small" do
      expect(divergence(2.0)).to eq(:asset_led)
    end

    it "calls a move within the threshold aligned" do
      expect(divergence(-3.2)).to eq(:aligned)
    end

    it "reads nothing when the asset has no change to compare" do
      expect(divergence(nil)).to be_nil
    end

    it "reads nothing when there is no index" do
      asset = create(:asset, :crypto)

      expect(context_for(asset)[:divergence]).to be_nil
    end
  end

  describe "sentiment" do
    it "reads a crypto asset against the crypto gauge" do
      create(:fear_greed_reading, :crypto, value: 20, classification: "Miedo extremo")

      expect(context_for(create(:asset, :crypto))[:sentiment].value).to eq(20)
    end

    it "gives an equity no gauge — the stocks index went with CNN (D38)" do
      create(:fear_greed_reading, :crypto, value: 20, classification: "Miedo extremo")

      expect(context_for(create(:asset, :stock))[:sentiment]).to be_nil
    end
  end
end
