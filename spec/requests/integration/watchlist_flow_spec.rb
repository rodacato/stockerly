require "rails_helper"

RSpec.describe "Watchlist flow", type: :request do
  let!(:user) { create(:user, email: "watchlist@example.com", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:onboarding_asset) { create(:asset) }
  let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL") }

  before do
    login_as(user)
  end

  it "adds asset to watchlist and shows on dashboard" do
    # Add to watchlist
    post watchlist_items_path, params: { asset_id: apple.id }
    expect(response).to redirect_to(dashboard_path)

    expect(user.watchlist_items.count).to eq(2)

    # Verify it shows on dashboard
    get dashboard_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AAPL")
  end

  it "removes asset from watchlist" do
    item = create(:watchlist_item, user: user, asset: apple)

    delete watchlist_item_path(item)
    expect(response).to redirect_to(profile_path)
    expect(user.watchlist_items.count).to eq(1)
  end
end
