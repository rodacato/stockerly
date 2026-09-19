require "rails_helper"

# Icons used to be a remote ligature font, so a page could render with the word
# `chevron_right` where the chevron belonged — three network hops had to land
# before a glyph existed. They are vendored SVGs now (ADR-0028), and these
# measure the two properties that buys, in the only place the cascade and the
# HTML parser actually exist.
RSpec.describe "Icons", type: :system, js: true do
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

  it "ships the glyph with the page, so nothing has to arrive for it to draw" do
    visit assets_path

    expect(page).to have_css("svg.icon path", visible: :all)
    expect(page.evaluate_script("document.querySelector('svg.icon path').getAttribute('d').length")).to be > 10
  end

  # Written `viewBox`, an HTML document parses it as `viewbox` and the SVG
  # branch of the parser case-corrects it. Unparsed, baseVal is 0 and every
  # icon draws as a corner of a 960 canvas.
  it "keeps a viewBox the browser actually parsed" do
    visit assets_path

    expect(page.evaluate_script("document.querySelector('svg.icon').viewBox.baseVal.width")).to eq(960)
  end

  it "lets a size class decide how big the icon is" do
    visit assets_path

    expect(computed("svg.icon.text-xl", "width")).to eq("20px")
  end

  it "draws the empty state's icon at the size the artboard does" do
    visit signals_path

    expect(page).to have_css("svg.icon.text-6xl", wait: 5)
    expect(computed("svg.icon.text-6xl", "width")).to eq("60px")
  end
end
