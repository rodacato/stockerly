require "rails_helper"

RSpec.describe "Alert management", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "alerts@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:preference) { create(:alert_preference, user: user) }

  before do
    visit login_path
    fill_in "Email", with: "alerts@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "displays alert page with create form and empty state" do
    visit alerts_path
    expect(page).to have_content("Trend Alerts")
    expect(page).to have_content("Create New Alert")
    expect(page).to have_content("No alert rules configured")
  end

  it "creates an alert rule via form" do
    create(:asset, symbol: "NVDA", name: "NVIDIA Corp.", current_price: 900.0)

    visit alerts_path
    fill_in "alert[asset_symbol]", with: "NVDA"
    select "Price Crosses Above", from: "alert[condition]"
    fill_in "alert[threshold_value]", with: "950"
    click_button "Set Alert"

    expect(page).to have_content("NVDA")
  end

  it "toggles alert rule from active to paused" do
    rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 200.0, status: :active)

    page.driver.submit :patch, toggle_alert_path(rule), {}
    visit alerts_path

    expect(page).to have_content("Paused")
  end

  it "deletes an alert rule" do
    rule = create(:alert_rule, user: user, asset_symbol: "TSLA", condition: :price_crosses_below, threshold_value: 150.0, status: :active)

    visit alerts_path
    expect(page).to have_content("TSLA")

    page.driver.delete alert_path(rule)
    visit alerts_path

    expect(page).not_to have_content("TSLA")
  end

  it "shows alert events in live feed" do
    create(:alert_event, user: user, asset_symbol: "MSFT", message: "Price crossed above $420", event_status: :triggered, triggered_at: 5.minutes.ago)

    visit alerts_path
    expect(page).to have_content("Live Alert Feed")
    expect(page).to have_content("Price crossed above $420")
  end

  it "displays delivery preferences" do
    visit alerts_path
    expect(page).to have_content("Delivery Preferences")
    expect(page).to have_content("Browser Push")
    expect(page).to have_content("Email Digest")
    expect(page).to have_content("SMS Notifications")
  end

  it "shows sentiment condition options in the form" do
    visit alerts_path
    expect(page).to have_select("alert[condition]", with_options: [ "Sentiment Above (F&G)", "Sentiment Below (F&G)" ])
  end

  it "creates a sentiment alert rule via form" do
    visit alerts_path
    fill_in "alert[asset_symbol]", with: "FG_CRYPTO"
    select "Sentiment Above (F&G)", from: "alert[condition]"
    fill_in "alert[threshold_value]", with: "75"
    click_button "Set Alert"

    expect(page).to have_content("F&G CRYPTO")
    expect(page).to have_content("Sentiment above")
  end

  it "displays sentiment rules with readable symbol" do
    create(:alert_rule, user: user, asset_symbol: "FG_STOCKS",
           condition: :sentiment_below, threshold_value: 25.0, status: :active)

    visit alerts_path
    expect(page).to have_content("F&G STOCKS")
    expect(page).to have_content("Sentiment below")
  end
end
