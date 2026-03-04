require "rails_helper"

RSpec.describe MarketData::UseCases::SyncCryptoFundamentals do
  let!(:crypto_asset) { create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto, current_price: 67_250) }
  let!(:stock_asset) { create(:asset, symbol: "AAPL", name: "Apple", asset_type: :stock, current_price: 227) }

  before do
    create(:integration, provider_name: "CoinGecko", pool_key_value: "test_key")
  end

  describe "#call" do
    context "with valid crypto asset" do
      before { stub_coingecko_markets }

      it "stores crypto market metrics in AssetFundamental" do
        result = described_class.call(asset: crypto_asset)

        expect(result).to be_success
        fundamental = result.value!
        expect(fundamental.period_label).to eq("CRYPTO_MARKET")
        expect(fundamental.metrics["circulating_supply"]).to eq("19600000.0")
        expect(fundamental.metrics["fully_diluted_valuation"]).to eq("1080000000000.0")
        expect(fundamental.metrics["ath_price"]).to eq("73750.0")
        expect(fundamental.metrics["total_volume_24h"]).to eq("28400000000.0")
        expect(fundamental.metrics["volume_market_cap_ratio"]).to be_present
      end
    end

    context "with non-crypto asset" do
      it "returns Failure with :invalid" do
        result = described_class.call(asset: stock_asset)

        expect(result).to be_failure
        expect(result.failure.first).to eq(:invalid)
      end
    end

    context "when gateway returns no data for symbol" do
      before { stub_coingecko_markets([]) }

      it "returns Failure with :not_found" do
        result = described_class.call(asset: crypto_asset)

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end
  end
end
