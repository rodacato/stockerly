require "rails_helper"

RSpec.describe "Earnings detail page", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "earnings_detail@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", currency: "USD") }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "earnings_detail@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders the es-MX detail page with EPS estimates" do
    event = create(:earnings_event, asset: asset, report_date: 5.days.from_now.to_date, estimated_eps: 2.50)
    visit earning_path(event)

    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("Fecha de reporte")
    expect(page).to have_content("EPS estimado")
    expect(page).to have_content("Por reportar")
  end

  it "shows 'Superó estimado' chip with surprise percent when actual beats" do
    event = create(:earnings_event, asset: asset, report_date: 5.days.ago.to_date, estimated_eps: 2.00, actual_eps: 2.30)
    visit earning_path(event)

    expect(page).to have_content("Superó estimado")
    expect(page).to have_content("15.0%")
  end

  it "shows the back link + ver detalle CTA" do
    event = create(:earnings_event, asset: asset, report_date: 5.days.from_now.to_date, estimated_eps: 2.00)
    visit earning_path(event)

    expect(page).to have_link("Volver al calendario")
    expect(page).to have_link("Ver detalle de AAPL")
  end
end
