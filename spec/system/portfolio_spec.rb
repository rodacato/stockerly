require "rails_helper"

RSpec.describe "Portfolio tabs", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "portfolio@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0) }
  let!(:tsla) { create(:asset, symbol: "TSLA", name: "Tesla, Inc.", current_price: 176.0) }

  let!(:open_position) { create(:position, portfolio: portfolio, asset: aapl, shares: 10, avg_cost: 150.0, status: :open) }
  let!(:closed_position) { create(:position, portfolio: portfolio, asset: tsla, shares: 0, avg_cost: 200.0, status: :closed, closed_at: 1.week.ago) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "portfolio@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "stacks the three lists in one scroll, with the figures on the Consolidado" do
    visit positions_path

    expect(page).to have_content("Historial")
    expect(page).to have_content("Movimientos")
    expect(page).to have_content("Dividendos cobrados")
    expect(page).to have_content("Posiciones cerradas")

    visit portfolio_path
    expect(page).to have_content("PATRIMONIO TOTAL")
  end

  # D43 dropped it: it duplicated Holdings, and is the likeliest reason nobody
  # ever linked to this screen.
  it "does not carry the open-positions list any more" do
    visit positions_path

    expect(page).to have_no_content("Posiciones abiertas")
  end
end
