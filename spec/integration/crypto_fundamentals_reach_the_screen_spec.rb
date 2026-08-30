require "rails_helper"

# The two halves of crypto fundamentals were written apart: CoinGecko's richest
# payload had no caller, and the extract that asks for supply, FDV and ATH had
# no producer. This is the seam between them, end to end.
RSpec.describe "Crypto fundamentals reach the screen", type: :request do
  let!(:user) { create(:user, email: "crypto@example.com", password: "password123") }
  let!(:btc) { create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto, current_price: 67_250) }

  before do
    create(:integration, provider_name: "CoinGecko", api_key_encrypted: "test_key")
    stub_coingecko_markets
    login_as(user)
  end

  it "shows nothing before the sync has run" do
    get market_asset_path(btc.symbol)

    expect(response.body).not_to include(I18n.t("market.metricas.circulating_supply.nombre"))
  end

  it "renders the coin's supply once the sync has run" do
    SyncCryptoFundamentalsJob.perform_now

    get market_asset_path(btc.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("market.metricas.circulating_supply.nombre"))
    expect(response.body).to include("19,600,000")
  end

  it "derives the volume-to-market-cap ratio the API does not serve" do
    SyncCryptoFundamentalsJob.perform_now

    presenter = MarketData::Domain::FundamentalPresenter.new(
      asset: btc.reload, fundamental: btc.asset_fundamentals.last
    )

    expect(presenter.volume_market_cap_ratio).to eq(0.0217)
  end
end
