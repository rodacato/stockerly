require "rails_helper"

RSpec.describe "Earnings detail page", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "earnings_detail@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0, exchange: "NASDAQ") }

  before do
    visit login_path
    fill_in "Email", with: "earnings_detail@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "navigates from calendar to event detail page" do
    event = create(:earnings_event, asset: asset,
                   report_date: Date.current.beginning_of_month + 15.days,
                   estimated_eps: 2.50)

    visit earnings_path
    click_link "AAPL"

    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("Report Date")
    expect(page).to have_content("Estimated EPS")
  end

  it "shows beat status with surprise percentage" do
    event = create(:earnings_event, asset: asset,
                   report_date: Date.current.beginning_of_month + 15.days,
                   estimated_eps: 2.00, actual_eps: 2.30)

    visit earning_path(event)

    expect(page).to have_content("Beat")
    expect(page).to have_content("15.0%")
  end

  it "shows link back to calendar" do
    event = create(:earnings_event, asset: asset,
                   report_date: Date.current.beginning_of_month + 15.days,
                   estimated_eps: 2.00)

    visit earning_path(event)

    expect(page).to have_link("Back to Calendar")
    expect(page).to have_link("View AAPL Details")
  end
end
