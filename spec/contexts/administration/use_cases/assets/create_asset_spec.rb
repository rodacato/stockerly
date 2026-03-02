require "rails_helper"

RSpec.describe Administration::Assets::CreateAsset do
  describe ".call" do
    let(:admin) { create(:user, :admin) }

    let(:valid_params) do
      { symbol: "MSFT", name: "Microsoft Corporation", asset_type: "stock" }
    end

    it "creates asset and returns Success" do
      result = described_class.call(admin: admin, params: valid_params)

      expect(result).to be_success
      asset = result.value!
      expect(asset).to be_persisted
      expect(asset.symbol).to eq("MSFT")
      expect(asset.name).to eq("Microsoft Corporation")
      expect(asset.sync_status).to eq("active")
    end

    it "publishes AssetCreated event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(MarketData::AssetCreated))

      described_class.call(admin: admin, params: valid_params)
    end

    it "auto-generates logo URL for stocks via Synth Finance" do
      result = described_class.call(admin: admin, params: valid_params)

      expect(result.value!.logo_url).to eq("https://logo.synthfinance.com/ticker/MSFT")
    end

    it "auto-generates logo URL for ETFs via Synth Finance" do
      result = described_class.call(admin: admin, params: valid_params.merge(asset_type: "etf", symbol: "SPY"))

      expect(result.value!.logo_url).to eq("https://logo.synthfinance.com/ticker/SPY")
    end

    it "auto-generates logo URL for known crypto via CoinGecko" do
      result = described_class.call(admin: admin, params: valid_params.merge(
        symbol: "BTC", name: "Bitcoin", asset_type: "crypto"
      ))

      expect(result.value!.logo_url).to include("coingecko.com")
    end

    it "leaves logo_url nil for unknown crypto" do
      result = described_class.call(admin: admin, params: valid_params.merge(
        symbol: "UNKNOWN", name: "Unknown Coin", asset_type: "crypto"
      ))

      expect(result.value!.logo_url).to be_nil
    end

    it "preserves explicit logo_url when provided" do
      custom_url = "https://example.com/custom-logo.png"
      result = described_class.call(admin: admin, params: valid_params.merge(logo_url: custom_url))

      expect(result.value!.logo_url).to eq(custom_url)
    end

    it "sets data_source to Polygon.io for US stocks" do
      result = described_class.call(admin: admin, params: valid_params.merge(country: "US"))

      expect(result.value!.data_source).to eq("Polygon.io")
    end

    it "sets data_source to Yahoo Finance for MX stocks" do
      result = described_class.call(admin: admin, params: valid_params.merge(country: "MX"))

      expect(result.value!.data_source).to eq("Yahoo Finance")
    end

    it "sets data_source to CoinGecko API for crypto" do
      result = described_class.call(admin: admin, params: valid_params.merge(
        symbol: "ETH", name: "Ethereum", asset_type: "crypto"
      ))

      expect(result.value!.data_source).to eq("CoinGecko API")
    end

    it "returns Failure for validation errors" do
      result = described_class.call(admin: admin, params: { symbol: "", name: "", asset_type: "" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for duplicate symbol" do
      create(:asset, symbol: "MSFT")

      result = described_class.call(admin: admin, params: valid_params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
