require "rails_helper"

RSpec.describe "Quick wins", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "qw@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    visit login_path
    fill_in "Email", with: "qw@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  describe "Fear & Greed card with inline sparkline" do
    it "shows F&G card with sparkline when readings exist" do
      create(:fear_greed_reading, :crypto, value: 30, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 50, fetched_at: 1.day.ago)

      visit dashboard_path
      expect(page).to have_content("Crypto Fear & Greed")
      expect(page).to have_css("svg[aria-label*='30-day trend']")
    end
  end

  describe "News watchlist filter" do
    let!(:apple) { create(:asset, symbol: "AAPL", name: "Apple Inc.") }
    let!(:apple_article) { create(:news_article, title: "Apple Earnings Beat", related_ticker: "AAPL", published_at: 1.hour.ago) }
    let!(:other_article) { create(:news_article, title: "Tesla Deliveries", related_ticker: "TSLA", published_at: 2.hours.ago) }

    before do
      create(:watchlist_item, user: user, asset: apple)
    end

    it "filters articles when My Watchlist is selected" do
      visit news_path(filter: "watchlist")
      expect(page).to have_content("Apple Earnings Beat")
      expect(page).not_to have_content("Tesla Deliveries")
    end

    it "shows all articles when All News is selected" do
      visit news_path
      expect(page).to have_content("Apple Earnings Beat")
      expect(page).to have_content("Tesla Deliveries")
    end
  end
end
