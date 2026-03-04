require "rails_helper"

RSpec.describe "Portfolio concentration", type: :request do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  describe "GET /portfolio" do
    context "with a concentrated portfolio" do
      before do
        asset = create(:asset, symbol: "BIG", current_price: 1000.0, sector: "Technology")
        create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      end

      it "renders concentration risk badge" do
        get portfolio_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Concentration Risk")
        expect(response.body).to include("Concentrated")
        expect(response.body).to include("BIG")
      end
    end

    context "with a well-distributed portfolio" do
      before do
        10.times do |i|
          asset = create(:asset, symbol: "D#{i}", current_price: 100.0, sector: "Sector#{i}")
          create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
        end
      end

      it "shows diversified label" do
        get portfolio_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Concentration Risk")
        expect(response.body).to include("Diversified")
      end
    end

    context "with no positions" do
      it "does not render concentration section" do
        portfolio # ensure exists

        get portfolio_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Concentration Risk")
      end
    end
  end
end
