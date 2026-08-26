require "rails_helper"

RSpec.describe Administration::UseCases::Assets::CreateAsset do
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
      expect(EventBus).to receive(:publish).with(an_instance_of(MarketData::Events::AssetCreated))

      described_class.call(admin: admin, params: valid_params)
    end

    it "auto-generates logo URL for stocks via Parqet" do
      result = described_class.call(admin: admin, params: valid_params)

      expect(result.value!.logo_url).to eq("https://assets.parqet.com/logos/symbol/MSFT")
    end

    it "auto-generates logo URL for ETFs via Parqet" do
      result = described_class.call(admin: admin, params: valid_params.merge(asset_type: "etf", symbol: "SPY"))

      expect(result.value!.logo_url).to eq("https://assets.parqet.com/logos/symbol/SPY")
    end

    it "skips logo URL for MX stocks" do
      result = described_class.call(admin: admin, params: valid_params.merge(country: "MX", symbol: "GENIUSSACV.MX"))

      expect(result.value!.logo_url).to be_nil
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

    # Provenance is what the first sync records, not what the country implies.
    # Guessing it here is how the asset detail came to name a provider that had
    # not served the asset in months.
    it "leaves data_source for the first sync to record" do
      %w[US MX].each do |country|
        result = described_class.call(admin: admin, params: valid_params.merge(symbol: "T#{country}", country: country))

        expect(result.value!.data_source).to be_nil
      end
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

    describe "currency capture (#45)" do
      it "persists currency when provided via params" do
        result = described_class.call(
          admin: admin,
          params: valid_params.merge(symbol: "WALMEX.MX", country: "MX", currency: "MXN")
        )

        expect(result).to be_success
        expect(result.value!.currency).to eq("MXN")
      end

      it "falls back to the Asset schema default (USD) when currency omitted" do
        result = described_class.call(admin: admin, params: valid_params)

        expect(result).to be_success
        expect(result.value!.currency).to eq("USD")
      end

      it "rejects currencies outside SUPPORTED_CURRENCIES" do
        result = described_class.call(
          admin: admin,
          params: valid_params.merge(currency: "EUR")
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end
  end
end
