require "rails_helper"

# Hoy's ? buttons sit beside the figure they explain. Only a browser can say
# whether a button lands on top of its number at the design's 390 px width.
RSpec.describe "Hoy help tips", type: :system, js: true do
  let!(:user) { create(:user, email: "hoy@test.com", password: "password123", preferred_currency: "MXN", onboarded_at: Time.current) }

  before do
    portfolio = user.portfolio || create(:portfolio, user: user)
    portfolio.update!(inception_date: 2.years.ago.to_date)
    asset = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70)
    create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)
    portfolio.snapshots.create!(date: 20.days.ago.to_date, currency: "MXN", total_value: 1_000)
    portfolio.snapshots.create!(date: 1.day.ago.to_date, currency: "MXN", total_value: 1_100)
    CetesRateHistory.record(term: "28", date: 2.years.ago.to_date, rate: 10.0)

    visit login_path
    fill_in "Correo electrónico", with: "hoy@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit dashboard_path
  end

  it "keeps the CETES comparison's button off the value it explains" do
    card = find("[data-help-url*='vs_cetes']")
    value = card.find("p.font-display")

    overlap = page.evaluate_script(<<~JS, card.find("button[data-action='click->metric-tooltip#toggle']"), value)
      ((button, value) => {
        const a = button.getBoundingClientRect(), b = value.getBoundingClientRect();
        return { overlaps: a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom,
                 width: a.width, height: a.height };
      })(arguments[0], arguments[1])
    JS

    expect(overlap["overlaps"]).to be(false)
    expect([ overlap["width"], overlap["height"] ]).to all(be >= 36)
  end
end
