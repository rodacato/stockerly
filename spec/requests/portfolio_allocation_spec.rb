require "rails_helper"

RSpec.describe "Portfolio allocation breakdown", type: :request do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  describe "GET /portfolio" do
    it "displays allocation by sector and by type tabs" do
      stock = create(:asset, :stock, sector: "Technology", current_price: 100)
      create(:position, portfolio: portfolio, asset: stock, shares: 10, status: :open)

      get portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("By Sector")
      expect(response.body).to include("By Type")
      expect(response.body).to include("Technology")
    end

    it "shows asset type label for stock positions" do
      stock = create(:asset, :stock, current_price: 100)
      create(:position, portfolio: portfolio, asset: stock, shares: 5, status: :open)

      get portfolio_path

      expect(response.body).to include("Stocks")
    end

    it "shows empty message when no positions" do
      portfolio # ensure exists

      get portfolio_path

      expect(response.body).to include("No allocation data yet")
    end
  end
end
