require "rails_helper"

# Google's icon sheet declares `.material-symbols-outlined { font-size: 24px }`
# unlayered, and an unlayered rule beats every Tailwind utility whatever the
# source order. Linking it made every icon 24px: the nav's `text-xl` and the
# empty state's `text-6xl` alike. It is imported into `layer(base)` instead, and
# this measures the cascade in a real browser, which is the only place it exists.
RSpec.describe "Icon sizes", type: :system, js: true do
  let!(:user) { create(:user, email: "icons@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "icons@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  def computed(selector, property)
    page.evaluate_script(
      "getComputedStyle(document.querySelector(#{selector.to_json})).#{property}"
    )
  end

  it "lets a size class reach the icon instead of Google's 24px" do
    visit assets_path

    expect(computed(".material-symbols-outlined.text-xl", "fontSize")).to eq("20px")
  end

  it "keeps the icon font applied, so a ligature does not render as its word" do
    visit assets_path

    expect(computed(".material-symbols-outlined", "fontFamily")).to include("Material Symbols Outlined")
  end

  it "draws the empty state's icon at the size the artboard does" do
    visit signals_path

    expect(page).to have_css(".material-symbols-outlined.text-6xl", wait: 5)
    expect(computed(".material-symbols-outlined.text-6xl", "fontSize")).to eq("60px")
  end
end
