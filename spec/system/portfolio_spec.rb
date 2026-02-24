require "rails_helper"

RSpec.describe "Portfolio tabs", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "portfolio@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 5000.0) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0) }
  let!(:tsla) { create(:asset, symbol: "TSLA", name: "Tesla, Inc.", current_price: 176.0) }

  let!(:open_position) { create(:position, portfolio: portfolio, asset: aapl, shares: 10, avg_cost: 150.0, status: :open, currency: "USD") }
  let!(:closed_position) { create(:position, portfolio: portfolio, asset: tsla, shares: 0, avg_cost: 200.0, status: :closed, currency: "USD", closed_at: 1.week.ago) }

  before do
    visit login_path
    fill_in "Email", with: "portfolio@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "shows portfolio summary cards" do
    visit portfolio_path
    expect(page).to have_content("Investment Portfolio")
    expect(page).to have_content("Total Portfolio Value")
    expect(page).to have_content("Available Buying Power")
  end

  it "shows open positions tab with position data" do
    visit portfolio_path(tab: "open")
    expect(page).to have_content("Open Positions")
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("10")
  end

  it "shows closed positions tab" do
    visit portfolio_path(tab: "closed")
    expect(page).to have_content("Closed Positions")
    expect(page).to have_content("Tesla, Inc.")
  end

  it "shows dividend history tab" do
    dividend = create(:dividend, asset: aapl, amount_per_share: 0.24, ex_date: 1.month.ago, pay_date: 3.weeks.ago)
    create(:dividend_payment, portfolio: portfolio, dividend: dividend, shares_held: 10, total_amount: 2.40, received_at: 3.weeks.ago)

    visit portfolio_path(tab: "dividends")
    expect(page).to have_content("Dividend History")
    expect(page).to have_content("AAPL")
  end

  it "shows trade log tab with trades" do
    create(:trade, portfolio: portfolio, asset: aapl, position: open_position, side: :buy, shares: 10, price_per_share: 150.0, total_amount: 1500.0, currency: "USD", executed_at: 1.month.ago)

    visit portfolio_path(tab: "trades")
    expect(page).to have_content("Trade Log")
    expect(page).to have_content("AAPL")
    expect(page).to have_content("buy")
  end
end
