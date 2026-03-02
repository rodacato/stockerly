require "rails_helper"

RSpec.describe "Market asset analyst target price", type: :request do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, :stock, current_price: 150.0) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    context "with analyst target data" do
      before do
        create(:asset_fundamental,
          asset: asset,
          period_label: "OVERVIEW",
          source: "api_overview",
          metrics: {
            "analyst_target_price" => "200.00",
            "fifty_two_week_high" => "210.00",
            "fifty_two_week_low" => "120.00"
          })
      end

      it "displays analyst price target with upside" do
        get market_asset_path(asset.symbol)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Analyst Price Target")
        expect(response.body).to include("Upside")
      end
    end

    context "with target below current price" do
      before do
        create(:asset_fundamental,
          asset: asset,
          period_label: "OVERVIEW",
          source: "api_overview",
          metrics: {
            "analyst_target_price" => "120.00",
            "fifty_two_week_high" => "180.00",
            "fifty_two_week_low" => "100.00"
          })
      end

      it "displays downside label" do
        get market_asset_path(asset.symbol)

        expect(response.body).to include("Downside")
      end
    end

    context "without analyst target data" do
      it "does not render the analyst target card" do
        get market_asset_path(asset.symbol)

        expect(response.body).not_to include("Analyst Price Target")
      end
    end
  end
end
