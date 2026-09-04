require "rails_helper"

# Asset detail surface (S10 #93 — Stockerly-2.0). Asserts es-MX copy,
# adaptive tab structure, and currency prefix. Behavioral specs for
# LoadAssetDetail live in spec/contexts/market_data/use_cases/.
RSpec.describe "Market Asset Detail", type: :request do
  let!(:user) { create(:user, email: "detail@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44, sector: "Technology", exchange: "NASDAQ", country: "US") }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders the asset detail page" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apple Inc.")
      expect(response.body).to include("AAPL")
    end

    # The header names the currency beside a single price, so it reads as a
    # suffix. D10's ISO prefix governs rows in a list that declared a different
    # currency — a different problem.
    it "renders the price with its currency" do
      get market_asset_path(asset.symbol)

      expect(response.body).to match(/227\.44/)
      expect(response.body).to match(/>USD</)
    end

    it "renders the es-MX asset-type chip for an equity" do
      get market_asset_path(asset.symbol)

      expect(response.body).to match(/>\s*Acción\s*</)
      expect(response.body).not_to include("Equity")
    end

    it "shows fundamental metrics when data exists" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "eps" => "6.07", "beta" => "1.24", "pe_ratio" => "31.25" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("market.metricas.pe_ratio.nombre"))
      expect(response.body).to include("Beta")
    end

    it "shows the es-MX empty state when no fundamentals" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin datos fundamentales")
    end

    it "redirects to Activos with an es-MX alert when asset not found" do
      get market_asset_path("INVALID")

      expect(response).to redirect_to(assets_path)
      follow_redirect!
      expect(flash[:alert]).to eq("Activo no encontrado")
    end

    it "shows watchlist status (es-MX) for watched assets" do
      create(:watchlist_item, user: user, asset: asset)
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Quitar de watchlist")
    end

    it "shows add-to-watchlist CTA (es-MX) for unwatched assets" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Agregar a watchlist")
    end

    # D36 flattened the sub-tabs into the artboard's single scroll. What used to
    # be a tab strip is now a section that is present or absent.
    it "omits the fundamentals and statements sections when their data is absent" do
      get market_asset_path(asset.symbol)

      expect(response.body).not_to include(I18n.t("market.fundamentals_block.titulo"))
      expect(response.body).not_to include(I18n.t("market.statements_tab.titulo"))
      expect(response.body).not_to include(I18n.t("market.dividend_history.titulo"))
    end

    it "renders the fundamentals and statements sections when data exists" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "pe_ratio" => "31.25" })
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 9, 28), fiscal_year: 2024,
        data: { "totalRevenue" => "394328000000" })

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.fundamentals_block.titulo"))
      expect(response.body).to include(I18n.t("market.statements_tab.titulo"))
    end

    it "offers the rest of the glossary behind one control rather than a screen" do
      # forward_pe and gross_margin sit outside the extract, so they are what
      # the accordion has to hold.
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "pe_ratio" => "31.25", "forward_pe" => "28.4", "gross_margin" => "0.46" })

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.fundamentals_block.ver_todos"))
      expect(response.body).to include("data-reveal-target=\"content\"")
    end

    it "shows the GAAP label inside the statements tab" do
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 9, 28), fiscal_year: 2024,
        data: { "totalRevenue" => "394328000000" })

      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("US GAAP")
    end

    it "renders the P/U history section when price history and EPS exist" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
             metrics: { "eps" => "6.07" })
      3.times do |i|
        create(:asset_price_history, asset: asset, date: (i + 1).days.ago.to_date, close: 200 + i)
      end

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Razón P/U histórica")
    end

    it "charts from our own closes, with no third-party widget" do
      3.times { |i| create(:asset_price_history, asset: asset, date: i.days.ago.to_date, close: 100 + i) }

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="chart"')
      expect(response.body).not_to include("tradingview")
    end

    it "renders the es-MX data-source caption" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include("Fuente:")
    end

    it "renders fixed income detail (yield card) for CETES assets" do
      cetes = create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 días",
                     yield_rate: 11.15, face_value: 10.0, maturity_date: 20.days.from_now.to_date)

      get market_asset_path(cetes.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Detalle de la emisión")
      expect(response.body).to match(/>\s*Renta fija\s*</)
      expect(response.body).to include("Banxico")
      expect(response.body).to include("Avance al vencimiento")
    end

    # #552: the view parsed a term out of `CETES_28D` while the catalogue
    # created `CETE28D`, so the progress band never rendered for the only CETES
    # the app ships. The symbol comes from the catalogue on purpose — renaming
    # it there without the view has to fail here.
    it "renders the maturity progress band for the catalogue's own CETES symbol" do
      symbol = Administration::Domain::AssetCatalog.all[:fixed_income].first[:symbol]
      cetes = create(:asset, :fixed_income, symbol: symbol, name: "CETES 28 días",
                     yield_rate: 11.15, face_value: 10.0, maturity_date: 20.days.from_now.to_date)

      get market_asset_path(cetes.symbol)

      expect(response.body).to include(I18n.t("market.fixed_income_detail.transcurridos", count: 8))
      expect(response.body).to include(I18n.t("market.fixed_income_detail.restantes", count: 20))
    end
  end
  # X14: the chart drew a 30-day window and its heading never said so, while a
  # row's sparkline draws seven sessions. Same silhouette, different scale.
  describe "the price chart's window" do
    it "states the window it actually queried" do
      asset = create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 120, sync_status: :active)
      3.times { |d| create(:asset_price_history, asset: asset, date: Date.current - d, close: 100 + d) }

      get market_asset_path(asset.symbol)

      expect(response.body).to include(
        I18n.t("market.precio.titulo", currency: "USD",
                                       days: MarketData::UseCases::LoadAssetDetail::CHART_DAYS)
      )
    end
  end
end
