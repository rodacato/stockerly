require "rails_helper"

RSpec.describe "Trade management", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "trade_mgmt@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 150.0, status: :open) }
  let!(:trade) do
    create(:trade, portfolio: portfolio, asset: asset, position: position,
           side: :buy, shares: 10.0, price_per_share: 150.0, total_amount: 1500.0,
           executed_at: 2.days.ago)
  end

  before do
    visit login_path
    fill_in "Email", with: "trade_mgmt@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "shows trade history page with actions column" do
    visit trades_path

    expect(page).to have_content("Trade History")
    expect(page).to have_content("Actions")
    expect(page).to have_content("AAPL")
  end

  it "excludes soft-deleted trades from the list" do
    trade.discard!
    visit trades_path

    expect(page).not_to have_content("AAPL")
    expect(page).to have_content("No trades yet")
  end

  it "shows edit and delete buttons for recent trades" do
    visit trades_path

    expect(page).to have_css("span", text: "edit")
    expect(page).to have_css("span", text: "delete")
  end

  it "hides action buttons for old trades" do
    trade.update_column(:executed_at, 31.days.ago)
    visit trades_path

    expect(page).not_to have_css("span", text: "edit")
    expect(page).not_to have_css("span", text: "delete")
  end
end
