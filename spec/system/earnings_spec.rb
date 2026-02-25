require "rails_helper"

RSpec.describe "Earnings calendar", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "earnings@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0) }
  let!(:tsla) { create(:asset, symbol: "TSLA", name: "Tesla, Inc.", current_price: 176.0) }

  before do
    visit login_path
    fill_in "Email", with: "earnings@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "displays earnings calendar heading and month navigation" do
    visit earnings_path
    expect(page).to have_content("Earnings Calendar")
    expect(page).to have_content(Date.current.strftime("%B %Y"))
  end

  it "shows earnings events on calendar with ticker symbols" do
    create(:earnings_event, asset: aapl, report_date: Date.current.beginning_of_month + 14.days)

    visit earnings_path
    expect(page).to have_content("AAPL")
  end

  it "filters by watchlist when My Watchlist is selected" do
    create(:watchlist_item, user: user, asset: aapl)
    create(:earnings_event, asset: aapl, report_date: Date.current.beginning_of_month + 14.days)
    create(:earnings_event, asset: tsla, report_date: Date.current.beginning_of_month + 15.days)

    visit earnings_path(filter: "watchlist")
    expect(page).to have_content("AAPL")
    expect(page).not_to have_content("TSLA")
  end

  it "navigates to next month" do
    next_month = Date.current.next_month
    visit earnings_path(date: next_month)
    expect(page).to have_content(next_month.strftime("%B %Y"))
  end

  it "displays beat badge for earnings that beat estimates" do
    create(:earnings_event, asset: aapl,
           report_date: Date.current.beginning_of_month + 10.days,
           estimated_eps: 2.00, actual_eps: 2.30)

    visit earnings_path
    expect(page).to have_css("span[title*='Beat']")
  end

  it "displays miss badge for earnings that missed estimates" do
    create(:earnings_event, asset: aapl,
           report_date: Date.current.beginning_of_month + 10.days,
           estimated_eps: 2.00, actual_eps: 1.70)

    visit earnings_path
    expect(page).to have_css("span[title*='Miss']")
  end

  it "shows no badge for pending earnings without actual EPS" do
    create(:earnings_event, asset: aapl,
           report_date: Date.current.beginning_of_month + 10.days,
           estimated_eps: 2.00, actual_eps: nil)

    visit earnings_path
    expect(page).not_to have_css("span[title*='Beat']")
    expect(page).not_to have_css("span[title*='Miss']")
  end

  it "shows beat/miss surprise percentage in title attribute" do
    create(:earnings_event, asset: aapl,
           report_date: Date.current.beginning_of_month + 10.days,
           estimated_eps: 2.00, actual_eps: 2.30)

    visit earnings_path
    expect(page).to have_css("span[title='Beat 15.0%']")
  end
end
