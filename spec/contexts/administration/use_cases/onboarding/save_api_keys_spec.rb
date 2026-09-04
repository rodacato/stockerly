require "rails_helper"

RSpec.describe Administration::UseCases::Onboarding::SaveApiKeys do
  describe ".call" do
    let!(:polygon) { create(:integration, :keyless, provider_name: "Alpaca") }
    let!(:coingecko) { create(:integration, :keyless, provider_name: "CoinGecko") }

    it "updates integrations with provided keys" do
      result = described_class.call(keys: {
        polygon.id.to_s => "poly_key_123",
        coingecko.id.to_s => "cg_key_456"
      })

      expect(result[:updated]).to eq(2)
      default_key = polygon.reload
      expect(default_key.api_key_encrypted).to eq("poly_key_123")
      expect(polygon.connection_status).to eq("connected")
    end

    it "skips blank values" do
      result = described_class.call(keys: {
        polygon.id.to_s => "poly_key_123",
        coingecko.id.to_s => ""
      })

      expect(result[:updated]).to eq(1)
    end

    it "skips unknown integration ids" do
      result = described_class.call(keys: { "999999" => "some_key" })

      expect(result[:updated]).to eq(0)
    end
  end
  # Setup writes no FX rate, so the wizard is where real history first arrives —
  # and pulling it is also the only on-the-spot check that a token works.
  describe "pulling Banxico history once its key is saved" do
    let!(:banxico) { create(:integration, :keyless, provider_name: "Banxico") }

    def banxico_returns(status:, body: nil)
      stub_request(:get, %r{series/#{MarketData::Gateways::BanxicoGateway::FIX_SERIES}/datos/})
        .to_return(status: status, body: body.to_s, headers: { "Content-Type" => "application/json" })
    end

    def fix_payload(datos)
      { bmx: { series: [ { idSerie: MarketData::Gateways::BanxicoGateway::FIX_SERIES, datos: datos } ] } }.to_json
    end

    it "stores the fixes it received and reports how many" do
      banxico_returns(status: 200, body: fix_payload([ { "fecha" => "11/05/2026", "dato" => "17.0100" } ]))

      result = described_class.call(keys: { banxico.id.to_s => "token-123" })

      expect(result[:fx]).to eq(1)
      expect(FxRateHistory.count).to eq(1)
    end

    it "reports the failure and leaves no rate behind when Banxico refuses" do
      banxico_returns(status: 500)

      result = described_class.call(keys: { banxico.id.to_s => "bad-token" })

      expect(result[:fx]).to eq(:failed)
      expect(FxRateHistory.count).to eq(0)
      expect(FxRate.count).to eq(0)
    end

    it "skips the pull when no Banxico key was given" do
      other = create(:integration, :keyless, provider_name: "CoinGecko")

      result = described_class.call(keys: { other.id.to_s => "cg-key" })

      expect(result[:fx]).to eq(:skipped)
    end
  end
end
