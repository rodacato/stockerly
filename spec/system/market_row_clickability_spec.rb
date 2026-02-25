require "rails_helper"

RSpec.describe "Market row clickability", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "market@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", asset_type: :stock, current_price: 189.0, change_percent_24h: 1.5) }

  before do
    visit login_path
    fill_in "Email", with: "market@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "renders market rows with row-link controller" do
    visit market_path
    expect(page).to have_css("tr[data-controller='row-link']")
  end

  it "renders chevron icon in market listing rows" do
    visit market_path
    expect(page).to have_css("span.material-symbols-outlined", text: "chevron_right")
  end

  it "links market rows to asset detail page" do
    visit market_path
    row = find("tr[data-row-link-url-value='/market/AAPL']")
    expect(row).to be_present
  end
end
