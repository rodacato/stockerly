require "rails_helper"

RSpec.describe "Market asset earnings tab", type: :request do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, :stock) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    context "with earnings data" do
      before do
        create(:earnings_event, asset: asset, report_date: 3.months.ago,
               estimated_eps: 2.50, actual_eps: 2.75, timing: :after_market_close)
        create(:earnings_event, asset: asset, report_date: 6.months.ago,
               estimated_eps: 2.00, actual_eps: 1.80, timing: :before_market_open)
      end

      it "displays the Earnings tab" do
        get market_asset_path(asset.symbol)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Earnings")
      end

      it "shows earnings table with beat/miss badges via lazy tab" do
        get market_asset_earnings_tab_path(asset.symbol)

        expect(response.body).to include("EPS Est.")
        expect(response.body).to include("EPS Actual")
        expect(response.body).to include("Beat")
        expect(response.body).to include("Miss")
      end
    end

    context "without earnings data" do
      it "shows empty state message via lazy tab" do
        get market_asset_earnings_tab_path(asset.symbol)

        expect(response.body).to include("No earnings data available")
      end
    end

    context "for crypto assets" do
      let(:crypto) { create(:asset, :crypto) }

      it "does not include Earnings tab" do
        get market_asset_path(crypto.symbol)

        expect(response.body).not_to include("No earnings data available")
      end
    end
  end
end
