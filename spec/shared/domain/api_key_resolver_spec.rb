require "rails_helper"

RSpec.describe ApiKeyResolver do
  describe ".for" do
    it "returns the key the provider is configured with" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: "polygon_key_123")

      expect(described_class.for("Alpaca")).to eq("polygon_key_123")
    end

    it "returns nil for an unknown provider" do
      expect(described_class.for("Nobody")).to be_nil
    end

    it "returns nil when the provider has no key configured" do
      create(:integration, provider_name: "Finnhub", api_key_encrypted: nil)

      expect(described_class.for("Finnhub")).to be_nil
    end

    it "does not leak one provider's key to another" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: "polygon_key_123")
      create(:integration, provider_name: "Banxico", api_key_encrypted: "banxico_key_456")

      expect(described_class.for("Banxico")).to eq("banxico_key_456")
    end

    it "resolves the same key on repeated calls — there is nothing to rotate" do
      create(:integration, provider_name: "Alpha Vantage", api_key_encrypted: "av_key_789")

      keys = Array.new(3) { described_class.for("Alpha Vantage") }

      expect(keys).to all(eq("av_key_789"))
    end
  end
end
