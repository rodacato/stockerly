require "rails_helper"

RSpec.describe "Admin Assets Search", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  before { create(:integration, provider_name: "Alpha Vantage") }

  describe "GET /admin/assets/search" do
    context "when authenticated as admin" do
      before { login_as(admin) }

      it "returns JSON with search results" do
        stub_alpha_vantage_ticker_search("AAPL", results: [
          { "1. symbol" => "AAPL", "2. name" => "Apple Inc.", "3. type" => "Equity",
            "4. region" => "United States", "5. marketOpen" => "09:30",
            "6. marketClose" => "16:00", "7. timezone" => "UTC-04",
            "8. currency" => "USD", "9. matchScore" => "1.0000" }
        ])

        get search_admin_assets_path, params: { q: "AAPL" },
          headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body.size).to eq(1)
        expect(body.first["symbol"]).to eq("AAPL")
        expect(body.first["asset_type"]).to eq("stock")
      end

      it "returns 422 for blank query" do
        get search_admin_assets_path, params: { q: "" },
          headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_content)
        body = response.parsed_body
        expect(body["error"]).to be_present
      end

      it "returns 422 when gateway fails" do
        stub_alpha_vantage_ticker_search_error(status: 500)

        get search_admin_assets_path, params: { q: "AAPL" },
          headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get search_admin_assets_path, params: { q: "AAPL" }

        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as regular user" do
      let!(:user) { create(:user, email: "user@example.com", password: "password123") }

      before { login_as(user) }

      it "redirects to dashboard" do
        get search_admin_assets_path, params: { q: "AAPL" }

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
