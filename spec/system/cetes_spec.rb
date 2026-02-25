require "rails_helper"

RSpec.describe "CETES detail page", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "cetes@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:cetes) do
    create(:asset, :fixed_income,
           symbol: "CETES_28D",
           name: "CETES 28 Days",
           yield_rate: 11.15,
           face_value: 10.0,
           maturity_date: 20.days.from_now.to_date,
           current_price: 9.914)
  end

  before do
    visit login_path
    fill_in "Email", with: "cetes@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "displays CETES detail page with yield information" do
    visit market_asset_path(cetes.symbol)

    expect(page).to have_content("CETES 28 Days")
    expect(page).to have_content("Fixed Income")
    expect(page).to have_content("Yield Information")
    expect(page).to have_content("11.15")
  end

  it "shows maturity progress and days to maturity" do
    visit market_asset_path(cetes.symbol)

    expect(page).to have_content("Maturity Progress")
    expect(page).to have_content("20 days remaining")
  end

  it "shows investment calculator section" do
    visit market_asset_path(cetes.symbol)

    expect(page).to have_content("Investment Calculator")
    expect(page).to have_content("Investment Cost")
    expect(page).to have_content("Value at Maturity")
    expect(page).to have_content("Total Return")
  end
end
