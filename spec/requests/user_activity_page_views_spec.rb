require "rails_helper"

# #172 — verifies AuthenticatedController#record_page_view records exactly
# one UserActivity row per successful HTML hit on a tracked controller#action.
RSpec.describe "UserActivity page-view capture (#172)", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
  end

  describe "tracked controllers" do
    it "records a page_view:dashboard#show row on GET /dashboard" do
      portfolio = create(:portfolio, user: user, buying_power: 1_000)
      asset     = create(:asset, :mexican, currency: "MXN", current_price: 100)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)

      expect {
        get dashboard_path
      }.to change(UserActivity.by_action("page_view:dashboard#show"), :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(UserActivity.last.user).to eq(user)
      expect(UserActivity.last.params).to include("controller" => "dashboard", "action" => "show")
    end

    it "records a page_view:market#index row on GET /market" do
      expect {
        get market_path
      }.to change(UserActivity.by_action("page_view:market#index"), :count).by(1)
    end

    it "records a page_view:portfolios#show row on GET /portfolio" do
      create(:portfolio, user: user)

      expect {
        get portfolio_path
      }.to change(UserActivity.by_action("page_view:portfolios#show"), :count).by(1)
    end
  end

  describe "exclusions (no double-counting)" do
    it "does NOT record when the request format is turbo_stream" do
      # dashboard_trending renders the trending partial as turbo_stream; it's
      # not in TRACKED_PAGE_VIEWS, so even an HTML hit doesn't count. What we
      # care about here is that an explicit format=turbo_stream on a tracked
      # path doesn't double-count alongside the HTML hit. Using params[:format]
      # exercises the explicit guard.
      create(:portfolio, user: user, buying_power: 1_000)

      expect {
        get dashboard_path, params: { format: "turbo_stream" }
      }.not_to change(UserActivity, :count)
    end

    it "does NOT record on a Turbo-Frame partial request" do
      create(:portfolio, user: user, buying_power: 1_000)

      expect {
        get dashboard_path, headers: { "Turbo-Frame" => "navbar-notifications" }
      }.not_to change(UserActivity, :count)
    end

    it "does NOT record unauthenticated requests" do
      delete logout_path

      expect {
        get login_path
      }.not_to change(UserActivity, :count)
    end
  end
end
