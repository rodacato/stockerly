require "rails_helper"

RSpec.describe "Prometheus metrics endpoint", type: :request do
  let(:token) { "test-metrics-token" }

  around do |example|
    previous = ENV["METRICS_TOKEN"]
    ENV["METRICS_TOKEN"] = token
    example.run
    ENV["METRICS_TOKEN"] = previous
  end

  def auth_header(value = token)
    { "Authorization" => "Bearer #{value}" }
  end

  describe "GET /metrics" do
    it "returns 200 with a known metric when the bearer token is valid" do
      create(:asset, sync_status: :active, price_updated_at: 5.minutes.ago)

      get "/metrics", headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("stockerly_data_age_seconds")
    end

    it "returns 401 without a token" do
      get "/metrics"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with a wrong token" do
      get "/metrics", headers: auth_header("nope")

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when no token is configured (fail closed)" do
      ENV["METRICS_TOKEN"] = nil

      get "/metrics", headers: auth_header

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "http_request_duration_seconds" do
    def scraped
      get "/metrics", headers: auth_header
      response.body
    end

    it "labels a request by its route pattern, not its path" do
      create(:user)

      get "/reset-password/not-a-real-token"

      expect(scraped).to include('http_request_duration_seconds_count{method="GET",route="/reset-password/:token",')
      expect(response.body).not_to include("not-a-real-token")
    end

    it "labels a path no route matches as unmatched" do
      get "/no-such-page"

      expect(scraped).to include('http_request_duration_seconds_count{method="GET",route="unmatched",status_code="404"}')
    end

    it "does not measure the scrape itself" do
      scraped

      expect(scraped).not_to include('route="unmatched",status_code="200"')
    end
  end
end
