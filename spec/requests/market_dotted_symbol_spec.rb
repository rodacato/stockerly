require "rails_helper"

# Mexican listings carry Yahoo's suffix (IVVPESO.MX); a route that reads ".MX"
# as a format sends every one of them to a 404.
RSpec.describe "The asset detail for a symbol with a dot", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let!(:asset) { create(:asset, :stock, symbol: "WALMEX.MX", currency: "MXN", country: "MX", current_price: 70) }

  before { login_as(user) }

  it "opens the detail page" do
    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("WALMEX.MX")
  end

  it "opens the lazy tabs and the link a view builds for it" do
    expect(market_asset_path(asset.symbol)).to eq("/market/WALMEX.MX")

    get market_asset_statements_tab_path(asset.symbol)
    expect(response).to have_http_status(:ok)

    get market_asset_earnings_tab_path(asset.symbol)
    expect(response).to have_http_status(:ok)
  end
end
