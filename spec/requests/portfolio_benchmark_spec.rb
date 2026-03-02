require "rails_helper"

RSpec.describe "Portfolio benchmark", type: :request do
  let!(:user) { create(:user, email: "bench@example.com", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:index) { create(:market_index, symbol: "SPX", name: "S&P 500") }

  before { login_as(user) }

  describe "GET /portfolio" do
    it "renders without benchmark by default" do
      get portfolio_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No Benchmark")
    end

    it "renders with benchmark selector showing options" do
      get portfolio_path
      expect(response.body).to include("S&P 500")
      expect(response.body).to include("NASDAQ")
      expect(response.body).to include("Dow Jones")
    end

    context "with benchmark parameter" do
      let!(:snap1) { create(:portfolio_snapshot, portfolio: portfolio, date: 10.days.ago.to_date, total_value: 10_000, invested_value: 10_000, cash_value: 0) }
      let!(:snap2) { create(:portfolio_snapshot, portfolio: portfolio, date: 1.day.ago.to_date, total_value: 10_500, invested_value: 10_000, cash_value: 500) }
      let!(:hist1) { create(:market_index_history, market_index: index, date: 10.days.ago.to_date, close_value: 5_000) }
      let!(:hist2) { create(:market_index_history, market_index: index, date: 1.day.ago.to_date, close_value: 5_250) }

      it "renders TWR comparison data" do
        get portfolio_path(benchmark: "SPX")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Portfolio TWR")
      end

      it "marks the selected benchmark in the dropdown" do
        get portfolio_path(benchmark: "SPX")
        expect(response.body).to include('value="SPX" selected')
      end
    end

    context "with invalid benchmark symbol" do
      it "ignores the benchmark gracefully" do
        get portfolio_path(benchmark: "INVALID")
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Portfolio TWR")
      end
    end

    context "with benchmark but no index history" do
      it "renders without benchmark data" do
        get portfolio_path(benchmark: "SPX")
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Portfolio TWR")
      end
    end
  end
end
