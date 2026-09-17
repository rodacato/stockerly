require "rails_helper"

RSpec.describe "Search", type: :request do
  let(:user) { create(:user) }

  before do
    create(:integration, provider_name: "Yahoo Finance")
    login_as(user)
  end

  describe "GET /search" do
    it "opens from the mobile top bar" do
      get dashboard_path

      expect(response.body).to include(%(href="#{search_path}"))
    end

    it "answers from the catalogue, linked to the asset, without asking Yahoo" do
      create(:asset, :stock, symbol: "ALAB", name: "Astera Labs, Inc.")

      get search_path, params: { q: "alab" }

      expect(response.body).to include("En tu catálogo", "Astera Labs, Inc.", %(href="#{market_asset_path("ALAB")}"))
      expect(PythonRunner).not_to have_received(:call).with("yahoo.py", "search", anything)
    end

    it "offers Yahoo's listings even when the catalogue matched" do
      create(:asset, :stock, symbol: "ALAB", name: "Astera Labs, Inc.")

      get search_path, params: { q: "alab" }

      expect(response.body).to include("Buscar «alab» en Yahoo Finance")
    end

    context "when the catalogue has no match" do
      before do
        stub_yfinance_search("asts", results: [
          yfinance_match(symbol: "ASTS", name: "AST SpaceMobile, Inc.", exchange: "NASDAQ"),
          yfinance_match(symbol: "ASTX", name: "Tradr 2X Long ASTS Daily ETF", quote_type: "ETF", exchange: "BATS Trading")
        ])
      end

      it "asks Yahoo and offers to track each result" do
        get search_path, params: { q: "asts" }

        expect(response.body).to include("Ningún activo rastreado coincide con «asts».", "En Yahoo Finance",
                                         "AST SpaceMobile, Inc. · NASDAQ", "Rastrear")
        expect(response.body).to include(%(action="#{track_asset_path}"))
      end
    end

    it "asks Yahoo alongside the catalogue when told to, leaving out what is already tracked" do
      create(:asset, :stock, symbol: "ALAB", name: "Astera Labs, Inc.")
      stub_yfinance_search("alab", results: [
        yfinance_match(symbol: "ALAB", name: "Astera Labs, Inc."),
        yfinance_match(symbol: "ALAB.MX", name: "Astera Labs, Inc.", exchange: "Mexico")
      ])

      get search_path, params: { q: "alab", scope: "yahoo" }

      expect(response.body).to include("En tu catálogo", "En Yahoo Finance", "Mexico")
      expect(response.body.scan("Rastrear").size).to eq(1)
    end

    # Negative: a Yahoo outage never hides what the catalogue already knows.
    it "keeps the catalogue and says so when Yahoo does not answer" do
      create(:asset, :stock, symbol: "ALAB", name: "Astera Labs, Inc.")
      stub_yfinance_search_failure("alab")

      get search_path, params: { q: "alab", scope: "yahoo" }

      expect(response.body).to include("Astera Labs, Inc.",
                                       "La búsqueda en Yahoo Finance no responde. Intenta de nuevo en un momento.")
    end

    it "says nothing matched anywhere, without offering an import" do
      stub_yfinance_search("zzqx", results: [])

      get search_path, params: { q: "zzqx" }

      expect(response.body).to include("Sin resultados", "Ni tu catálogo ni Yahoo Finance tienen «zzqx».")
      expect(response.body).not_to include("Rastrear", "Ningún activo rastreado coincide")
    end

    it "shows only the field before anything is typed" do
      get search_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("En tu catálogo", "Sin resultados")
    end
  end

  describe "tracking from the results" do
    it "lands on the new asset's page" do
      post track_asset_path, params: {
        asset: { symbol: "ASTS", name: "AST SpaceMobile, Inc.", asset_type: "stock", country: "US", exchange: "NASDAQ" },
        return_to: "market"
      }

      expect(response).to redirect_to(market_asset_path("ASTS"))
      expect(flash[:notice]).to eq("ASTS se agregó a Tracked.")
    end

    # Negative: the Tracked form keeps landing where it always did.
    it "still returns the Tracked form to Tracked" do
      post track_asset_path, params: { asset: { symbol: "ASTS", name: "AST SpaceMobile, Inc.", asset_type: "stock" } }

      expect(response).to redirect_to(tracked_assets_path)
    end
  end
end
