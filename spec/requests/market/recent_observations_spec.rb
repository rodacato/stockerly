require "rails_helper"

# Recent observations panel on /market/:symbol (#40 JTBD #6 + #93). Copy is
# es-MX descriptive per ADR-001; panel title is "Observaciones recientes".
RSpec.describe "Market detail — Recent Observations block (#40 JTBD #6)", type: :request do
  let(:user) { create(:user, email: "viewer@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock, current_price: 145.0) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders recent observations when they exist" do
      create(:technical_observation, asset: asset, observation_type: "rsi_oversold_entered", observed_at: 1.day.ago)
      create(:technical_observation, asset: asset, observation_type: "ma200_crossed_below", observed_at: 5.days.ago)

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Observaciones recientes")
      expect(response.body).to include("entró en zona de sobreventa")
      expect(response.body).to include("cruzó a la baja su MA200")
    end

    it "does not render the panel when the asset has no observations" do
      get market_asset_path(asset.symbol)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Observaciones recientes")
    end

    it "filters to observations within the last 30 days" do
      create(:technical_observation, asset: asset, observation_type: "rsi_oversold_entered", observed_at: 5.days.ago)
      create(:technical_observation, asset: asset, observation_type: "ma50_crossed_above", observed_at: 45.days.ago)

      get market_asset_path(asset.symbol)
      expect(response.body).to include("entró en zona de sobreventa")
      expect(response.body).not_to include("cruzó al alza su MA50")
    end

    # ADR-014 lets the verdict card read a state out loud, from a catalogue. The
    # observations block is not that card: it stays descriptive, so the reading
    # a phrase came from is always available in plain language.
    it "keeps the observations block descriptive" do
      create(:technical_observation, asset: asset, observation_type: "bb_upper_breached", observed_at: 1.hour.ago)

      get market_asset_path(asset.symbol)
      block = response.body[/Observaciones recientes.*?<\/section>/m].to_s

      expect(block).to include("rompió la banda de Bollinger superior")
      expect(block).not_to match(/\b(comprar|vender|rebalancear|considera|considere|deberías?|debes|es momento)\b/i)
    end
  end
end
