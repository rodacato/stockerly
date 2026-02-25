require "rails_helper"

RSpec.describe "Search", type: :request do
  let!(:user) { create(:user, email: "search@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", current_price: 189.0) }
  let!(:news) { create(:news_article, title: "Apple earnings beat estimates", related_ticker: "AAPL", published_at: 1.hour.ago) }

  before { post login_path, params: { email: "search@test.com", password: "password123" } }

  describe "GET /search" do
    it "renders the full search page" do
      get search_path, params: { q: "apple" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Search Results")
      expect(response.body).to include("Apple Inc.")
    end

    it "renders modal partial for modal format" do
      get search_path, params: { q: "apple", format: "modal" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
      expect(response.body).to include("Apple Inc.")
      expect(response.body).not_to include("Search Results")
    end

    it "returns no results message for unmatched query" do
      get search_path, params: { q: "zzzznotfound", format: "modal" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No results found")
    end

    it "includes news articles in modal results" do
      get search_path, params: { q: "apple", format: "modal" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("earnings beat")
    end

    it "returns asset links pointing to market detail page" do
      get search_path, params: { q: "AAPL", format: "modal" }
      expect(response.body).to include("/market/AAPL")
    end
  end
end
