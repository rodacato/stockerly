require "rails_helper"

# Two pick-one-of-N controls that commit through JavaScript. The theme lives in
# localStorage, so the server renders all three unselected and the controller
# has to announce the selection itself — a control drawn as selected while it
# announces nothing is what this pins.
RSpec.describe "Ajustes — Apariencia", type: :system, js: true do
  let!(:user) do
    create(:user, email: "apariencia@test.com", password: "password123",
                  onboarded_at: Time.current, preferred_currency: "MXN")
  end

  before do
    visit login_path
    fill_in "Correo electrónico", with: "apariencia@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit settings_path
  end

  def theme_group = find("[role='tablist'][aria-label='#{I18n.t("settings.show.tema_control")}']")
  def currency_group = find("[role='tablist'][aria-label='#{I18n.t("settings.show.moneda")}']")

  it "announces the theme its controller applied, not a silent default" do
    expect(theme_group).to have_css("[role='tab'][aria-selected='true']", count: 1)
    expect(theme_group).to have_css("[role='tab'][aria-selected='true']", text: I18n.t("settings.show.tema_sistema"))
  end

  it "moves the announcement with the pick" do
    theme_group.find("[role='tab']", text: I18n.t("settings.show.tema_oscuro")).click

    expect(theme_group).to have_css("[role='tab'][aria-selected='true']", text: I18n.t("settings.show.tema_oscuro"))
    expect(theme_group).to have_css("[role='tab'][aria-selected='false']", count: 2)
  end

  it "starts the currency group on the stored preference" do
    expect(currency_group).to have_css("[role='tab'][aria-selected='true']", text: "MXN")
  end

  it "moves it to the currency it persisted" do
    currency_group.find("[role='tab']", text: "USD").click

    expect(currency_group).to have_css("[role='tab'][aria-selected='true']", text: "USD")
    expect(user.reload.preferred_currency).to eq("USD")
  end
end
