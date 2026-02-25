require "rails_helper"

RSpec.describe "Earnings show", type: :request do
  let!(:user) { create(:user, email: "earnings@test.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0, exchange: "NASDAQ") }
  let!(:event) { create(:earnings_event, asset: asset, report_date: 1.month.from_now, estimated_eps: 2.50) }

  before { login_as(user) }

  describe "GET /earnings/:id" do
    it "renders the earnings detail page" do
      get earning_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apple Inc.")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("Report Date")
      expect(response.body).to include("Estimated EPS")
    end

    it "shows pending status when no actual EPS" do
      get earning_path(event)

      expect(response.body).to include("Pending")
    end

    it "shows beat badge when actual exceeds estimated" do
      event.update!(actual_eps: 2.80)
      get earning_path(event)

      expect(response.body).to include("Beat")
    end

    it "shows miss badge when actual is below estimated" do
      event.update!(actual_eps: 2.10)
      get earning_path(event)

      expect(response.body).to include("Miss")
    end

    it "includes link to asset detail page" do
      get earning_path(event)

      expect(response.body).to include("/market/AAPL")
    end

    it "shows back link to calendar" do
      get earning_path(event)

      expect(response.body).to include("Back to Calendar")
    end
  end
end
