require "rails_helper"

RSpec.describe "Progress bar in app layout", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
    create(:watchlist_item, user: user)
  end

  describe "GET /dashboard" do
    it "includes progress bar Stimulus controller" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="progress-bar"')
    end

    it "includes progress bar target element" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-progress-bar-target="bar"')
    end
  end
end
