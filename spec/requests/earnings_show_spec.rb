require "rails_helper"

RSpec.describe "Earnings show", type: :request do
  let!(:user)  { create(:user, email: "earnings@test.com", password: "password123") }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", currency: "USD") }
  let!(:event) { create(:earnings_event, asset: asset, report_date: 1.month.from_now, estimated_eps: 2.50) }

  before { login_as(user) }

  describe "GET /earnings/:id" do
    it "renders the earnings detail page in es-MX" do
      get earning_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apple Inc.")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("Fecha de reporte")
      expect(response.body).to include("EPS estimado")
    end

    it "shows 'Por reportar' status when no actual EPS" do
      get earning_path(event)
      expect(response.body).to include("Por reportar")
    end

    it "shows 'Superó estimado' when actual exceeds estimated" do
      event.update!(actual_eps: 2.80)
      get earning_path(event)
      expect(response.body).to include("Superó estimado")
    end

    it "shows 'Por debajo' when actual is below estimated" do
      event.update!(actual_eps: 2.10)
      get earning_path(event)
      expect(response.body).to include("Por debajo")
    end

    it "links to the asset detail page" do
      get earning_path(event)
      expect(response.body).to include("/market/AAPL")
    end

    it "shows back link to calendar" do
      get earning_path(event)
      expect(response.body).to include("Volver al calendario")
    end
  end
end
