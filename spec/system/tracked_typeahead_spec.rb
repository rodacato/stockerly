require "rails_helper"

# The typeahead paints its rows in the browser, so only a browser proves the
# chip reads the es-MX glossary rather than the enum the endpoint returns.
RSpec.describe "Tracked typeahead", type: :system, js: true do
  let!(:user) { create(:user, email: "typeahead@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    create(:integration, provider_name: "Yahoo Finance")
    stub_yfinance_search("AAPL", results: [ yfinance_match(symbol: "AAPL", name: "Apple Inc.") ])

    visit login_path
    fill_in "Correo electrónico", with: "typeahead@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit tracked_assets_path
  end

  it "labels a result's type in es-MX" do
    click_button I18n.t("assets.tracked.agregar")
    fill_in "ticker_query", with: "AAPL"

    within("[data-ticker-search-target='results']") do
      expect(page).to have_content("ACCIÓN")
      expect(page).to have_no_content("STOCK")
    end
  end
end
