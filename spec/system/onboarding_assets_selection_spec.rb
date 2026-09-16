require "rails_helper"

# The picker preselects a few assets. Their highlight used to be decided on the
# server, so unticking one left it looking chosen while the form would skip it.
RSpec.describe "Onboarding asset picker", type: :system, js: true do
  let!(:user) { create(:user, :admin, email: "picker@test.com", password: "password123", onboarded_at: nil) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "picker@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit onboarding_assets_path
  end

  def background_of(symbol)
    page.evaluate_script(<<~JS)
      getComputedStyle(document.querySelector('input[value="#{symbol}"]').closest("label")).backgroundColor
    JS
  end

  def settled_background_of(symbol)
    previous = nil
    10.times do
      current = background_of(symbol)
      return current if current == previous
      previous = current
      sleep 0.1
    end
    previous
  end

  it "stops highlighting an asset once it is unticked" do
    unselected = settled_background_of("TSLA")
    expect(settled_background_of("AAPL")).not_to eq(unselected)

    find('input[value="AAPL"]').uncheck

    expect(settled_background_of("AAPL")).to eq(unselected)
  end

  it "highlights an asset once it is ticked" do
    unselected = settled_background_of("TSLA")

    find('input[value="TSLA"]').check

    expect(settled_background_of("TSLA")).not_to eq(unselected)
  end
end
