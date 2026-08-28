require "rails_helper"

RSpec.describe "Historial", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset) { create(:asset, symbol: "AAPL", currency: "USD") }

  before { login_as(user) }

  describe "the three sections" do
    it "stacks them in one scroll, with no tab control" do
      portfolio
      get positions_path

      expect(response.body).to include("Movimientos", "Dividendos cobrados", "Posiciones cerradas")
      # D43 dropped this tab: it duplicated Holdings, and is the likeliest
      # reason nobody ever linked to the screen.
      expect(response.body).not_to include("Posiciones abiertas")
    end

    it "declares each section's currency in its header, per D10" do
      portfolio
      get positions_path

      expect(response.body).to include("Valores en la moneda de cada operación")
      expect(response.body).to include("Ganancia realizada, en MXN")
    end

    it "shows an empty state per section rather than one for the page" do
      portfolio
      get positions_path

      expect(response.body).to include("Aún no registras movimientos")
      expect(response.body).to include("Aún no has cobrado dividendos")
      expect(response.body).to include("Aún no cierras ninguna posición")
    end
  end

  describe "the trade log" do
    let!(:position) { create(:position, portfolio: portfolio, asset: asset) }
    let!(:trade) do
      create(:trade, portfolio: portfolio, position: position, asset: asset,
                     side: :buy, shares: 12, price_per_share: 172.40,
                     currency: "USD", fx_rate_at_execution: 18)
    end

    it "keeps the ISO prefix on each row, because the rows genuinely mix" do
      get positions_path

      expect(response.body).to include("AAPL")
      expect(response.body).to include("USD")
      expect(response.body).to include("compra")
    end

    it "renders rows as cards rather than table rows (KIT-4)" do
      get positions_path

      expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(trade)}"))
      expect(response.body).not_to include("<table")
    end
  end

  describe "closed positions" do
    let!(:closed) { create(:position, portfolio: portfolio, asset: asset, status: :closed, closed_at: 3.days.ago) }

    before do
      create(:trade, portfolio: portfolio, position: closed, asset: asset,
                     side: :buy, shares: 10, price_per_share: 100, currency: "USD", fx_rate_at_execution: 17)
      create(:trade, portfolio: portfolio, position: closed, asset: asset,
                     side: :sell, shares: 10, price_per_share: 120, currency: "USD", fx_rate_at_execution: 18)
    end

    it "states what the position actually made, at each leg's own rate" do
      get positions_path

      # 10*120*18 − 10*100*17 = 4,600
      expect(response.body).to include("4,600")
    end

    it "says so rather than guessing when a leg lost its captured rate" do
      closed.trades.first.update_column(:fx_rate_at_execution, nil)

      get positions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("sin TC")
    end
  end

  # The capability that had to survive the merge: editing and deleting a trade
  # lived on /trades, which is gone.
  describe "editing and deleting a movement, inline" do
    let!(:position) { create(:position, portfolio: portfolio, asset: asset) }
    let!(:trade) { create(:trade, portfolio: portfolio, position: position, asset: asset, currency: "USD", fx_rate_at_execution: 18) }

    it "swaps the card for an edit form in place" do
      get edit_trade_path(trade), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(trade))
      expect(response.body).to include("Guardar")
    end

    it "confirms a delete in place instead of through a JS dialog" do
      get confirm_destroy_trade_path(trade), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("Sí, eliminar")
    end

    it "sends the reader back to Historial, not to the route that is gone" do
      delete trade_path(trade)

      expect(response).to redirect_to(positions_path)
    end
  end

  describe "how anyone gets here" do
    # D60: the design drew Historial without a door. Its only inbound link was
    # from one asset's detail, and /trades is gone.
    it "is reachable from the foot of Activos, beside Tracked" do
      portfolio
      get assets_path

      expect(response.body).to include(positions_path)
    end
  end
end
