require "rails_helper"

RSpec.describe "Market asset dividend history", type: :request do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, :stock) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    context "with dividend data" do
      before do
        create(:dividend, asset: asset, ex_date: 3.months.ago, amount_per_share: 0.24, pay_date: 2.months.ago)
        create(:dividend, asset: asset, ex_date: 6.months.ago, amount_per_share: 0.22, pay_date: 5.months.ago)
      end

      it "displays dividend history table" do
        get market_asset_path(asset.symbol)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Historial de dividendos")
      end

      it "shows amount per share values with the native currency prefix" do
        get market_asset_path(asset.symbol)

        expect(response.body).to match(/USD\s+0\.2400/)
        expect(response.body).to match(/USD\s+0\.2200/)
      end
    end

    context "without dividend data" do
      it "does not render dividend history section" do
        get market_asset_path(asset.symbol)

        expect(response.body).not_to include("Historial de dividendos")
      end
    end
  end
end
