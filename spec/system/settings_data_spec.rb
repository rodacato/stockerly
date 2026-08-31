require "rails_helper"

# Both buttons POST through Turbo behind a confirm dialog, and neither is
# exercised by a request spec -- request specs do not run Turbo, which is how
# the importer's happy path once stayed broken while its specs were green.
RSpec.describe "Ajustes — Datos", type: :system, js: true do
  let!(:user) { create(:user, email: "datos@test.com", password: "password123", onboarded_at: Time.current, preferred_currency: "MXN") }
  let!(:portfolio) { create(:portfolio, user: user, inception_date: Date.new(2025, 11, 11)) }
  let!(:asset) { create(:asset, :etf, symbol: "VT", currency: "USD") }

  before do
    position = create(:position, portfolio: portfolio, asset: asset)
    create(:trade, portfolio: portfolio, asset: asset, position: position)
    create(:portfolio_snapshot, portfolio: portfolio)

    visit login_path
    fill_in "Correo electrónico", with: "datos@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "clears the movements and leaves the account signed in" do
    visit settings_path
    expect(page).to have_content("Borrar mis movimientos")

    accept_confirm { click_button "Borrar movimientos" }

    expect(page).to have_content("ya puedes importar de nuevo")
    expect(portfolio.trades.count).to eq(0)
    expect(portfolio.positions.count).to eq(0)
    expect(portfolio.reload.inception_date).to be_nil
    expect(User.exists?(user.id)).to be(true)
    expect(Asset.where(symbol: "VT")).to exist
  end

  # setup_bypass: false so this account really is the only one -- with the
  # sentinel user still present /setup bounces straight back and the assertion
  # would prove nothing about a real instance.
  it "deletes the account and lands on the setup wizard", setup_bypass: false do
    visit settings_path

    accept_confirm { click_button "Borrar cuenta" }

    expect(page).to have_current_path(setup_path, wait: 5)
    expect(User.exists?(user.id)).to be(false)
  end
end
