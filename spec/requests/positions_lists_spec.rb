require "rails_helper"

# What survived the Consolidado replacing /portfolio: the four lists, now at
# their own route with no nav entry. The S09 header, the KPI strip, the inline
# trade form and the tabbed allocation sidebar went with the old screen — the
# sheet at /trades/new and the Consolidado's donut are their replacements.
RSpec.describe "Posiciones y movimientos", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before do
    login_as(user)
    portfolio # LoadPortfolio redirects without one, and the let is lazy
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
  end

  it "renders the four tab labels in es-MX" do
    get positions_path

    expect(response.body).to include("Posiciones abiertas")
    expect(response.body).to include("Cerradas")
    expect(response.body).to include("Dividendos")
    expect(response.body).to include("Movimientos")
  end

  it "keeps the ISO prefix on a position in its own currency" do
    asset = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 189.0)
    create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 150.0, status: :open)

    get positions_path

    expect(response.body).to include("USD 189.00")
  end

  it "offers a way back to the Consolidado" do
    get positions_path

    expect(response.body).to include(%(href="#{portfolio_path}"))
  end

  it "uses the shared empty state when there are no open positions" do
    get positions_path

    expect(response.body).to include("Aún no hay posiciones abiertas")
  end
end
