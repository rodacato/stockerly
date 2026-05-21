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

    it "renders the price block with the native currency prefix" do
      get market_asset_path(asset.symbol)

      expect(response.body).to match(/USD\s+227\.44/)
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
      expect(response.body).to include("P/E Ratio")
      expect(response.body).to include("Beta")
    end

    it "shows the es-MX empty state when no fundamentals" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin datos fundamentales")
    end

    it "redirects to market index with an es-MX alert when asset not found" do
      get market_asset_path("INVALID")

      expect(response).to redirect_to(market_path)
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

    it "renders the always-visible Resumen tab" do
      get market_asset_path(asset.symbol)

      expect(response.body).to match(/>\s*Resumen\s*</)
    end

    it "drops 4-letter tabs when fundamentals/dividends/statements are absent" do
      get market_asset_path(asset.symbol)

      expect(response.body).not_to match(/>\s*Valoración\s*</)
      expect(response.body).not_to match(/>\s*Dividendos\s*</)
      expect(response.body).not_to match(/>\s*Estados financieros\s*</)
    end

    it "renders Valoración + Estados financieros tabs when data exists" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "pe_ratio" => "31.25" })
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 9, 28), fiscal_year: 2024,
        data: { "totalRevenue" => "394328000000" })

      get market_asset_path(asset.symbol)

      expect(response.body).to match(/>\s*Valoración\s*</)
      expect(response.body).to match(/>\s*Estados financieros\s*</)
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

    it "renders the TradingView chart widget for stocks" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="tradingview"')
      expect(response.body).to include('data-tradingview-symbol-value="NASDAQ:AAPL"')
    end

    it "renders the es-MX data-source caption" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include("Fuente:")
    end

    context "on-demand fundamental sync" do
      it "enqueues SyncFundamentalJob when no fundamentals exist" do
        expect {
          get market_asset_path(asset.symbol)
        }.to have_enqueued_job(SyncFundamentalJob).with(asset.id)
      end

      it "does not enqueue when fundamentals were recently synced" do
        asset.update!(fundamentals_synced_at: 5.minutes.ago)

        expect {
          get market_asset_path(asset.symbol)
        }.not_to have_enqueued_job(SyncFundamentalJob)
      end

      it "enqueues when fundamentals are stale (> 10 minutes)" do
        asset.update!(fundamentals_synced_at: 15.minutes.ago)

        expect {
          get market_asset_path(asset.symbol)
        }.to have_enqueued_job(SyncFundamentalJob).with(asset.id)
      end

      it "does not enqueue for crypto assets" do
        crypto = create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto)

        expect {
          get market_asset_path(crypto.symbol)
        }.not_to have_enqueued_job(SyncFundamentalJob)
      end

      it "does not enqueue when fundamentals already present" do
        create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
               metrics: { "eps" => "6.07" })

        expect {
          get market_asset_path(asset.symbol)
        }.not_to have_enqueued_job(SyncFundamentalJob)
      end
    end

    it "renders fixed income detail (yield card) for CETES assets" do
      cetes = create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 días",
                     yield_rate: 11.15, face_value: 10.0, maturity_date: 20.days.from_now.to_date)

      get market_asset_path(cetes.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Detalle de la emisión")
      expect(response.body).to match(/>\s*CETE\s*</)
      expect(response.body).to include("Banxico")
      expect(response.body).to include("Avance al vencimiento")
    end
  end
end
