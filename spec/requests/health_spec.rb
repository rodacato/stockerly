require "rails_helper"

RSpec.describe "Health Endpoint", type: :request do
  describe "GET /health" do
    it "returns ok status when all checks pass" do
      create(:asset, sync_status: :active, price_updated_at: 5.minutes.ago)
      SystemLog.create!(task_name: "Market Indices Sync", module_name: "sync", severity: :success,
                        duration_seconds: 0, created_at: 10.minutes.ago)
      SystemLog.create!(task_name: "FX Rates Sync", module_name: "sync", severity: :success,
                        duration_seconds: 0, created_at: 1.hour.ago)

      get "/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
      expect(json["checks"]["prices"]).to eq("ok")
      expect(json["checks"]["indices"]).to eq("ok")
      expect(json["checks"]["fx_rates"]).to eq("ok")
    end

    it "returns degraded when a check exceeds ok threshold" do
      create(:asset, sync_status: :active, price_updated_at: 30.minutes.ago)

      get "/health"

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("degraded")
      expect(json["checks"]["prices"]).to eq("degraded")
    end

    it "returns critical with 503 when a check exceeds degraded threshold" do
      create(:asset, sync_status: :active, price_updated_at: 2.hours.ago)

      get "/health"

      expect(response).to have_http_status(:service_unavailable)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("critical")
      expect(json["checks"]["prices"]).to eq("critical")
    end

    it "returns ok when no data exists yet (first boot)" do
      get "/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
    end

    it "does not require authentication" do
      get "/health"

      expect(response).not_to have_http_status(:unauthorized)
      expect(response).not_to redirect_to("/login")
    end
  end
end
