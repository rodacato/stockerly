require "rails_helper"

RSpec.describe "Portfolio risk metrics", type: :request do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  describe "GET /portfolio" do
    context "with insufficient snapshot data" do
      it "shows not enough data message" do
        portfolio # ensure portfolio exists

        get portfolio_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Not enough data")
      end
    end

    context "with sufficient snapshot data (31+ days)" do
      before do
        35.times do |i|
          value = 10_000 + (i * 50)
          create(:portfolio_snapshot,
            portfolio: portfolio,
            date: (35 - i).days.ago.to_date,
            total_value: value,
            cash_value: 1_000,
            invested_value: 9_000)
        end
      end

      it "displays volatility, Sharpe ratio, and max drawdown" do
        get portfolio_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Annualized Volatility")
        expect(response.body).to include("Sharpe Ratio")
        expect(response.body).to include("Max Drawdown")
      end

      it "displays risk metric labels" do
        get portfolio_path

        expect(response.body).to include("Risk Metrics")
        expect(response.body).to include("Risk-adjusted return")
      end
    end
  end
end
