require "rails_helper"

# The rule form shows a field only where the contract reads it. A calendar rule
# ignores the threshold, a marketwide one has no asset, and both used to be asked
# for anyway; the cooldown was asked for and silently dropped.
RSpec.describe "Rule form fields", type: :system, js: true do
  let!(:user) { create(:user, email: "rule-form@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    create(:portfolio, user: user)
    create(:alert_preference, user: user)
    visit login_path
    fill_in "Correo electrónico", with: "rule-form@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit new_alert_path
  end

  it "labels a day-change threshold as a percentage, not a price" do
    click_button "% cambio en el día"

    expect(page).to have_content("Cambio en el día · %")
    expect(page).to have_no_content("Umbral de precio")
  end

  it "previews an inclusive threshold, the way the evaluator compares it" do
    click_button "RSI sobrecomprado"
    fill_in "alert[asset_symbol]", with: "nvda"
    fill_in "alert[threshold_value]", with: "70"

    expect(page).to have_content("Te avisaremos cuando el RSI(14) de NVDA esté en 70 o más.")
  end

  # D10: every amount names its currency, and the browser cannot know the one an
  # asset quotes in — the symbol is typed into a free-text field. So the preview
  # states the rule and leaves the figure to the field above it, instead of
  # printing a bare number the saved rule then shows as `cruza USD 200 al alza`.
  it "previews a price rule without repeating the amount it cannot name a currency for" do
    first("[data-condition='price_crosses_above']").click
    fill_in "alert[asset_symbol]", with: "aapl"
    fill_in "alert[threshold_value]", with: "200"

    preview = find("[data-alert-form-target='preview']")
    expect(preview).to have_text("Te avisaremos cuando AAPL cruce ese precio al alza.")
    expect(preview).to have_no_text("200")
  end

  it "previews a day-change rule instead of the generic sentence" do
    click_button "% cambio en el día"
    fill_in "alert[asset_symbol]", with: "BTC"
    fill_in "alert[threshold_value]", with: "6"

    expect(page).to have_content("Te avisaremos cuando BTC se mueva 6% o más en el día.")
  end

  it "hides the threshold for a calendar rule and the asset for a marketwide one" do
    click_button "Subasta CETES"

    expect(page).to have_field("alert[window_days]")
    expect(page).to have_no_field("alert[threshold_value]")
    expect(page).to have_no_field("alert[asset_symbol]")
  end

  it "saves the cooldown typed into the form" do
    create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 150)
    create(:asset, symbol: "NVDA")
    visit alerts_path
    click_link "Nueva"

    fill_in "alert[asset_symbol]", with: "NVDA"
    fill_in "alert[threshold_value]", with: "200"
    fill_in "alert[cooldown_minutes]", with: "240"
    click_button "Crear regla"

    expect(page).to have_content("espera 240 min entre avisos")
    expect(user.alert_rules.last.cooldown_minutes).to eq(240)
  end
end
