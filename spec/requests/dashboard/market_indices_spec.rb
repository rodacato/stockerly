require "rails_helper"

RSpec.describe "Dashboard market indices", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
    create(:watchlist_item, user: user)
  end

  describe "GET /dashboard" do
    it "displays market indices section" do
      create(:market_index, symbol: "SPX", name: "S&P 500", value: 5_200.50, change_percent: 0.75, is_open: true)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Market Indices")
      expect(response.body).to include("SPX")
      expect(response.body).to include("S&amp;P 500")
    end

    it "shows change percentage with color coding" do
      create(:market_index, symbol: "NDX", name: "Nasdaq 100", value: 18_500.0, change_percent: -1.25, is_open: false)

      get dashboard_path

      expect(response.body).to include("NDX")
      expect(response.body).to include("trending_down")
    end

    it "renders sparkline when history exists" do
      idx = create(:market_index, symbol: "DJI", name: "Dow Jones", value: 39_000.0, change_percent: 0.5, is_open: true)
      3.times do |i|
        create(:market_index_history, market_index: idx, date: i.days.ago.to_date, close_value: 39_000 + (i * 100))
      end

      get dashboard_path

      expect(response.body).to include("DJI")
    end

    it "shows open/closed indicator dot" do
      create(:market_index, symbol: "SPX", name: "S&P 500", value: 5_200.0, change_percent: 0.5, is_open: true)

      get dashboard_path

      expect(response.body).to include("animate-pulse")
    end
  end
end
