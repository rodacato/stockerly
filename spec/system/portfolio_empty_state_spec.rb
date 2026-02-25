require "rails_helper"

RSpec.describe "Portfolio empty state", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "empty@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 10_000.0) }

  before do
    visit login_path
    fill_in "Email", with: "empty@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "shows summary cards even with no positions" do
    visit portfolio_path
    expect(page).to have_content("Investment Portfolio")
    expect(page).to have_content("Total Portfolio Value")
    expect(page).to have_content("Available Buying Power")
  end

  it "shows the trade form on empty portfolio" do
    visit portfolio_path
    expect(page).to have_content("Log a Trade")
    expect(page).to have_button("Execute Trade", visible: :all)
  end

  it "shows header action buttons on empty portfolio" do
    visit portfolio_path
    expect(page).to have_link("Trade Log")
    expect(page).to have_link("Explore Markets")
  end

  it "shows positions table with empty state message" do
    visit portfolio_path
    expect(page).to have_content("No open positions yet")
  end
end
