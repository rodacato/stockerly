require "rails_helper"

RSpec.describe "Dashboard caching", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "cache@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }

  around do |example|
    original_store = Rails.cache
    original_caching = ActionController::Base.perform_caching
    memory_store = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.perform_caching = true
    Rails.cache = memory_store
    example.run
  ensure
    Rails.cache = original_store
    ActionController::Base.perform_caching = original_caching
  end

  before do
    visit login_path
    fill_in "Email", with: "cache@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "renders watchlist table with caching enabled" do
    asset = create(:asset, symbol: "CACHED1", name: "Cached Asset", current_price: 100.0)
    create(:watchlist_item, user: user, asset: asset)

    visit dashboard_path

    expect(page).to have_content("Cached Asset")
    expect(page).to have_content("Watchlist Performance")
  end

  it "renders trending section with cached content" do
    create(:asset, symbol: "HOT", name: "Hot Stock", asset_type: :stock, current_price: 50.0, change_percent_24h: 10.0)

    visit dashboard_path

    expect(page).to have_content("Trending Today")
    expect(page).to have_content("HOT")
  end

  it "renders weekly insight with cached content" do
    visit dashboard_path

    expect(page).to have_content("Weekly Insight")
  end

  it "renders market status with cached content" do
    create(:market_index, symbol: "SPX", exchange: "NYSE")

    visit dashboard_path

    expect(page).to have_content("Market Status")
  end

  it "busts watchlist row cache when asset price changes" do
    asset = create(:asset, symbol: "BUST", name: "Cache Bust", current_price: 100.0)
    create(:watchlist_item, user: user, asset: asset)

    visit dashboard_path
    expect(page).to have_content("$100.00")

    asset.update!(current_price: 150.0)

    visit dashboard_path
    expect(page).to have_content("$150.00")
  end

  it "loads dashboard without errors when cache is cold" do
    Rails.cache.clear

    visit dashboard_path

    expect(page).to have_content("Dashboard")
  end
end
