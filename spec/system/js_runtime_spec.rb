require "rails_helper"

# The first spec in this project to execute JavaScript. Until now all ~40 system
# specs ran on rack_test, so none of the Stimulus controllers had ever been run
# by a test — this pins that the pipeline itself works before anything relies on
# it. What it cannot cover is D11's real target: the iOS keyboard covering a
# bottom-anchored sheet does not reproduce in headless Chrome on Linux.
RSpec.describe "JavaScript runtime", type: :system, js: true do
  let!(:user) { create(:user, email: "js@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "js@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "boots Stimulus" do
    expect(page.evaluate_script("typeof window.Stimulus")).to eq("object")
  end

  it "loads the importmap modules the shell depends on" do
    expect(page.evaluate_script("typeof window.Turbo")).to eq("object")
  end

  # rack_test renders both nav variants and cannot tell which one CSS picks.
  # At 390px the bottom bar is the visible one; the sidebar is not.
  it "shows the mobile nav and hides the sidebar at the design's base width" do
    expect(page).to have_css("nav.sticky.bottom-0", visible: :visible)
    expect(page).to have_no_css("aside nav", visible: :visible)
  end
end
