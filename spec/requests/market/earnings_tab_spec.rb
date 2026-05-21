require "rails_helper"

# Earnings sub-page (S10 #93). Earnings was removed as an embedded tab on
# /market/:symbol — the endpoint /market/:symbol/earnings_tab still
# renders standalone (linked from elsewhere, e.g. /earnings calendar drill-in).
RSpec.describe "Market asset earnings tab", type: :request do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, :stock) }

  before { login_as(user) }

  describe "GET /market/:symbol/earnings_tab" do
    context "with earnings data" do
      before do
        create(:earnings_event, asset: asset, report_date: 3.months.ago,
               estimated_eps: 2.50, actual_eps: 2.75, timing: :after_market_close)
        create(:earnings_event, asset: asset, report_date: 6.months.ago,
               estimated_eps: 2.00, actual_eps: 1.80, timing: :before_market_open)
      end

      it "renders the lazy endpoint with the es-MX surface" do
        get market_asset_earnings_tab_path(asset.symbol)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Historial de EPS")
      end

      it "shows the earnings table with es-MX beat/miss badges" do
        get market_asset_earnings_tab_path(asset.symbol)

        expect(response.body).to include("EPS estimado")
        expect(response.body).to include("EPS real")
        expect(response.body).to include("Superó")
        expect(response.body).to include("Por debajo")
      end
    end

    context "without earnings data" do
      it "shows the es-MX empty state" do
        get market_asset_earnings_tab_path(asset.symbol)

        expect(response.body).to include("Sin reportes disponibles")
      end
    end

    context "for crypto assets" do
      let(:crypto) { create(:asset, :crypto) }

      it "renders the empty state when crypto's lazy endpoint is hit" do
        get market_asset_earnings_tab_path(crypto.symbol)

        expect(response.body).to include("Sin reportes disponibles")
      end
    end
  end
end
