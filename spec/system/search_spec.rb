require "rails_helper"

RSpec.describe "Global search", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "search@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", current_price: 189.0) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "search@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  # The 2.0 TopBar is logo + bell; the redesign puts search inside
  # Activos › Rastreados, which its slice has not built yet. /search stays
  # routable meanwhile, with no entry point — pinned so it reads as a decision.
  it "is no longer reachable from the shell" do
    visit dashboard_path
    expect(page).not_to have_css("[data-controller='search']")
    expect(page).not_to have_link(href: search_path)
  end

  it "renders the full search results page" do
    visit search_path(q: "apple")
    expect(page).to have_content("Search Results")
    expect(page).to have_content("Apple Inc.")
  end

  it "shows no results message for unmatched query" do
    visit search_path(q: "zzzznotfound")
    expect(page).to have_content("No results found")
  end
end
