require "rails_helper"

RSpec.describe "Health Endpoint", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  # Thursday 13:00 ET / 11:00 CDMX — both sessions past the opening grace, so
  # the market-gated price checks are actually evaluated.
  let(:session) { Time.utc(2026, 9, 3, 17, 0, 0) }

  describe "GET /health" do
    it "returns ok status when all checks pass" do
      travel_to(session) do
        create(:asset, sync_status: :active, price_updated_at: 5.minutes.ago, country: "US")
        SystemLog.create!(task_name: "Market Indices Sync", module_name: "sync", severity: :success,
                          duration_seconds: 0, created_at: 10.minutes.ago)
        SystemLog.create!(task_name: "FX Rate Refresh", module_name: "sync", severity: :success,
                          duration_seconds: 0, created_at: 1.hour.ago)

        get "/health"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("ok")
        expect(json["checks"]["prices_us"]).to eq("ok")
        expect(json["checks"]["indices"]).to eq("ok")
        expect(json["checks"]["fx_rates"]).to eq("ok")
      end
    end

    it "returns degraded when a check exceeds ok threshold" do
      travel_to(session) do
        create(:asset, sync_status: :active, price_updated_at: 30.minutes.ago, country: "US")

        get "/health"

        json = JSON.parse(response.body)
        expect(json["status"]).to eq("degraded")
        expect(json["checks"]["prices_us"]).to eq("degraded")
      end
    end

    it "returns critical with 503 when a check exceeds degraded threshold" do
      travel_to(session) do
        create(:asset, sync_status: :active, price_updated_at: 2.hours.ago, country: "US")

        get "/health"

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("critical")
        expect(json["checks"]["prices_us"]).to eq("critical")
      end
    end

    # The reason /health is per asset class (#553): a crypto sync that never
    # stops used to answer for equities that had.
    it "reports critical when one asset class stalls while another is live" do
      travel_to(session) do
        create(:asset, :crypto, price_updated_at: 1.minute.ago)
        create(:asset, sync_status: :active, price_updated_at: 4.hours.ago, country: "US")

        get "/health"

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json["checks"]["prices_crypto"]).to eq("ok")
        expect(json["checks"]["prices_us"]).to eq("critical")
      end
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
