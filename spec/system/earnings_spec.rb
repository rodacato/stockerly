require "rails_helper"

RSpec.describe "Earnings calendar", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "earnings@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  let!(:aapl) { create(:asset, :stock, symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", currency: "USD") }
  let!(:nvda) { create(:asset, :stock, symbol: "NVDA", name: "NVIDIA Corp.", exchange: "NASDAQ", currency: "USD") }
  let!(:walmex) { create(:asset, :stock, symbol: "WALMEX.MX", name: "Walmart de México", exchange: "BMV", currency: "MXN") }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "earnings@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders the header eyebrow + h1 + KPI cards" do
    visit earnings_path

    expect(page).to have_content("Reportes trimestrales")
    expect(page).to have_content("Calendario de reportes")
    expect(page).to have_content("Período actual")
    expect(page).to have_content("En tu watchlist")
  end

  it "lists upcoming events grouped by date with es-MX day headers" do
    create(:earnings_event, asset: aapl,   report_date: 2.days.from_now.to_date, estimated_eps: 1.65)
    create(:earnings_event, asset: walmex, report_date: 4.days.from_now.to_date, estimated_eps: 1.24)

    visit earnings_path

    expect(page).to have_content("AAPL")
    expect(page).to have_content("WALMEX.MX")
    expect(page).to have_content("Próximos")
    expect(page).to have_content((2.days.from_now.to_date).day.to_s)
  end

  it "filters by mercado=BMV" do
    create(:earnings_event, asset: aapl,   report_date: 2.days.from_now.to_date)
    create(:earnings_event, asset: walmex, report_date: 3.days.from_now.to_date)

    visit earnings_path(mercado: "BMV")

    expect(page).to have_content("WALMEX.MX")
    expect(page).not_to have_content(/^AAPL$/)
  end

  it "filters by watchlist_only" do
    create(:watchlist_item, user: user, asset: walmex)
    create(:earnings_event, asset: walmex, report_date: 3.days.from_now.to_date)
    create(:earnings_event, asset: nvda,   report_date: 4.days.from_now.to_date)

    visit earnings_path(watchlist_only: true)

    expect(page).to have_content("WALMEX.MX")
    expect(page).not_to have_content("NVDA")
  end

  it "renders the empty-watchlist state when no matches" do
    visit earnings_path(watchlist_only: true)
    expect(page).to have_content("No hay reportes en tu watchlist para este filtro.")
  end

  it "renders the recent section for events in the last 7 days with delta" do
    create(:earnings_event, asset: nvda, report_date: 3.days.ago.to_date, estimated_eps: 5.00, actual_eps: 5.30)

    visit earnings_path
    expect(page).to have_content("Recientes")
    expect(page).to have_content("Reportado")
    expect(page).to have_content("NVDA")
  end

  it "switches period via the segmented control" do
    visit earnings_path
    click_link "Este mes"
    expect(current_url).to include("periodo=mes")
  end

  it "marks unconfirmed BMV events with the 'fecha por confirmar' tag" do
    create(:earnings_event, asset: walmex, report_date: 4.days.from_now.to_date, confirmed: false)
    visit earnings_path
    expect(page).to have_content("fecha por confirmar")
  end
end
