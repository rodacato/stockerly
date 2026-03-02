require "rails_helper"

RSpec.describe "Session timeout", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { create(:user, email: "timeout@example.com", password: "password123") }

  before { login_as(user) }

  describe "inactivity timeout (30 minutes)" do
    it "expires session after 30 minutes of inactivity" do
      travel_to 31.minutes.from_now do
        get dashboard_path
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("inactivity")
      end
    end

    it "keeps session alive when active within 30 minutes" do
      travel_to 15.minutes.from_now do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      travel_to 40.minutes.from_now do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "absolute timeout (12 hours)" do
    it "expires session after 12 hours regardless of activity" do
      # Keep active every 20 minutes for 12 hours
      36.times do |i|
        travel_to((i * 20).minutes.from_now) do
          get dashboard_path
        end
      end

      # At 12 hours + 1 minute, session should be expired
      travel_to 12.hours.from_now + 1.minute do
        get dashboard_path
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("expired")
      end
    end
  end

  describe "session refresh on activity" do
    it "updates last_activity_at on each request" do
      get dashboard_path
      expect(response).to have_http_status(:ok)

      travel_to 29.minutes.from_now do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      # 29 minutes after the refresh, should still be active
      travel_to 58.minutes.from_now do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "unauthenticated requests" do
    it "does not trigger timeout check for public pages" do
      reset!
      travel_to 31.minutes.from_now do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
