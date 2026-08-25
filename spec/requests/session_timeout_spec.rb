require "rails_helper"

RSpec.describe "Session timeout", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { create(:user, email: "timeout@example.com", password: "password123") }

  before { login_as(user) }

  describe "inactivity timeout (14 days)" do
    it "expires the session after 14 days of inactivity" do
      travel_to 14.days.from_now + 1.minute do
        get dashboard_path
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("inactividad")
      end
    end

    it "survives a weekly visit, which is the cadence the product is built for" do
      4.times do |week|
        travel_to((week + 1).weeks.from_now) do
          get dashboard_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "absolute timeout (30 days)" do
    it "expires the session after 30 days regardless of activity" do
      29.times do |day|
        travel_to((day + 1).days.from_now) { get dashboard_path }
      end

      travel_to 30.days.from_now + 1.minute do
        get dashboard_path
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("expiró")
      end
    end
  end

  describe "session refresh on activity" do
    it "updates last_activity_at on each request" do
      travel_to 13.days.from_now do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      # 13 days after that refresh — 26 in total, past the inactivity window
      # measured from login, but not from the last request.
      travel_to 26.days.from_now do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "unauthenticated requests" do
    it "does not trigger timeout check for public pages" do
      reset!
      travel_to 31.days.from_now do
        get login_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
