require "rails_helper"

RSpec.describe Administration::UseCases::Onboarding::SaveApiKeys do
  describe ".call" do
    let!(:polygon) { create(:integration, :keyless, provider_name: "Polygon.io") }
    let!(:coingecko) { create(:integration, :keyless, provider_name: "CoinGecko") }

    it "updates integrations with provided keys" do
      result = described_class.call(keys: {
        polygon.id.to_s => "poly_key_123",
        coingecko.id.to_s => "cg_key_456"
      })

      expect(result).to be_success
      expect(result.value![:updated]).to eq(2)
      default_key = polygon.reload.api_key_pools.default_key.first
      expect(default_key.api_key_encrypted).to eq("poly_key_123")
      expect(polygon.connection_status).to eq("connected")
    end

    it "skips blank values" do
      result = described_class.call(keys: {
        polygon.id.to_s => "poly_key_123",
        coingecko.id.to_s => ""
      })

      expect(result).to be_success
      expect(result.value![:updated]).to eq(1)
    end

    it "skips unknown integration ids" do
      result = described_class.call(keys: { "999999" => "some_key" })

      expect(result).to be_success
      expect(result.value![:updated]).to eq(0)
    end
  end
end
