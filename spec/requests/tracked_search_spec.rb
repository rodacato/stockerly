require "rails_helper"

RSpec.describe "Tracked ticker search", type: :request do
  let!(:user) { create(:user, email: "user@example.com", password: "password123") }

  before { create(:integration, provider_name: "Yahoo Finance") }

  describe "GET /tracked/search" do
    context "when authenticated" do
      before { login_as(user) }

      it "returns JSON with search results" do
        stub_yfinance_search("AAPL", results: [
          yfinance_match(symbol: "AAPL", name: "Apple Inc.", sector: "Technology")
        ])

        get search_tickers_path, params: { q: "AAPL" },
          headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body.size).to eq(1)
        expect(body.first["symbol"]).to eq("AAPL")
        expect(body.first["asset_type"]).to eq("stock")
        expect(body.first["sector"]).to eq("Technology")
      end

      it "returns 422 for blank query" do
        get search_tickers_path, params: { q: "" },
          headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_content)
        body = response.parsed_body
        expect(body["error"]).to be_present
      end

      it "returns 422 when gateway fails" do
        stub_yfinance_search_failure("AAPL")

        get search_tickers_path, params: { q: "AAPL" },
          headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get search_tickers_path, params: { q: "AAPL" }

        expect(response).to redirect_to(login_path)
      end
    end
  end
end
