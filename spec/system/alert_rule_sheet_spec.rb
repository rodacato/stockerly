require "rails_helper"

RSpec.describe "Rule sheet after submit", type: :system, js: true do
  let!(:user) { create(:user, email: "sheet@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:preference) { create(:alert_preference, user: user) }

  before do
    create(:asset, symbol: "NVDA", name: "NVIDIA Corp.", current_price: 900.0)
    visit login_path
    fill_in "Correo electrónico", with: "sheet@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  def open_new_sheet
    visit alerts_path
    click_link "Nueva"
    expect(page).to have_css("dialog[open]")
  end

  it "closes after a rule is created" do
    create(:alert_rule, user: user, asset_symbol: "NVDA", condition: :price_crosses_below, threshold_value: 100)
    open_new_sheet
    fill_in "alert[asset_symbol]", with: "NVDA"
    fill_in "alert[threshold_value]", with: "950"
    click_button "Crear regla"

    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_css("#alert_rules", text: /950/)
    expect(page).to have_current_path(alerts_path)
    expect(user.alert_rules.count).to eq(2)
  end

  it "closes after a rule is edited" do
    rule = create(:alert_rule, user: user, asset_symbol: "NVDA", condition: :price_crosses_above, threshold_value: 950)
    visit alerts_path
    find("##{ActionView::RecordIdentifier.dom_id(rule)} a[href='#{edit_alert_path(rule)}']").click
    expect(page).to have_css("dialog[open]")
    fill_in "alert[threshold_value]", with: "1000"
    within("dialog") { click_button "Guardar cambios" }

    expect(page).to have_no_css("dialog[open]")
    expect(rule.reload.threshold_value).to eq(1000)
  end

  it "stays open when the rule is rejected" do
    open_new_sheet
    fill_in "alert[asset_symbol]", with: "NOEXISTE"
    fill_in "alert[threshold_value]", with: "950"
    click_button "Crear regla"

    expect(page).to have_css("dialog[open]")
    expect(AlertRule.where(user: user)).to be_empty
  end
end
