require "rails_helper"

RSpec.describe "Trade flow", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "trader@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 150.0) }

  before do
    visit login_path
    fill_in "Email", with: "trader@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "executes a buy trade and shows position in portfolio" do
    page.driver.post trades_path, trade: {
      asset_symbol: "AAPL", side: "buy", shares: "10", price_per_share: "150.0"
    }

    visit portfolio_path
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("10")
  end

  it "executes a sell trade and reduces position shares" do
    create(:position, portfolio: portfolio, asset: asset, shares: 20, avg_cost: 100.0, status: :open, currency: "USD")

    page.driver.post trades_path, trade: {
      asset_symbol: "AAPL", side: "sell", shares: "5", price_per_share: "150.0"
    }

    visit portfolio_path
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("15")
  end

  it "closes position when selling all shares" do
    create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0, status: :open, currency: "USD")

    page.driver.post trades_path, trade: {
      asset_symbol: "AAPL", side: "sell", shares: "10", price_per_share: "150.0"
    }

    visit portfolio_path(tab: "closed")
    expect(page).to have_content("Apple Inc.")
  end

  it "shows trade in Trade Log tab after execution" do
    page.driver.post trades_path, trade: {
      asset_symbol: "AAPL", side: "buy", shares: "5", price_per_share: "150.0"
    }

    visit portfolio_path(tab: "trades")
    expect(page).to have_content("AAPL")
    expect(page).to have_content("buy")
  end
end
