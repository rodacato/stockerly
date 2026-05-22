require "rails_helper"

# Asset detail end-to-end coverage across the four primary asset types
# (S10 #93). Confirms the Stockerly-2.0 surface renders correctly per type:
# - stock  → equity layout with Resumen + Valoración + Dividendos + Estados financieros
# - etf    → equity layout (no statements/dividends if absent → trimmed)
# - crypto → Resumen + Mercado only, never financial-statement tabs
# - fixed_income → yield card replaces tabs
RSpec.describe "Asset detail (adaptive by type)", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "adet@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "adet@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  describe "stock (equity)" do
    let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", asset_type: :stock, currency: "USD", current_price: 227.44, change_percent_24h: 1.5, exchange: "NASDAQ", country: "US") }

    it "renders the Stockerly-2.0 header with native currency prefix and Acción chip" do
      visit market_asset_path(apple.symbol)

      expect(page).to have_content("AAPL")
      expect(page).to have_content("Apple Inc.")
      expect(page).to have_content("Acción")
      expect(page).to have_content(/USD\s+227\.44/)
    end

    it "exposes the always-visible Resumen tab and the es-MX watchlist CTA" do
      visit market_asset_path(apple.symbol)

      expect(page).to have_button("Resumen")
      expect(page).to have_button("Agregar a watchlist")
    end

    it "shows Valoración + Estados financieros when fundamentals + statements exist" do
      create(:asset_fundamental, asset: apple, period_label: "OVERVIEW",
        metrics: { "pe_ratio" => "31.25" })
      create(:financial_statement, asset: apple, statement_type: :income_statement,
        period_type: :annual, fiscal_date_ending: Date.new(2024, 9, 28),
        fiscal_year: 2024, data: { "totalRevenue" => "394328000000" })

      visit market_asset_path(apple.symbol)

      expect(page).to have_button("Valoración")
      expect(page).to have_button("Estados financieros")
    end
  end

  describe "ETF" do
    let!(:voo) { create(:asset, :etf, name: "Vanguard S&P 500 ETF", symbol: "VOO", currency: "USD", current_price: 540.12, change_percent_24h: 0.45) }

    it "renders the ETF chip and trims tabs to Resumen only when no data" do
      visit market_asset_path(voo.symbol)

      expect(page).to have_content("VOO")
      expect(page).to have_content("ETF")
      expect(page).to have_button("Resumen")
      expect(page).not_to have_button("Valoración")
      expect(page).not_to have_button("Estados financieros")
    end

    it "shows the es-MX empty state when no fundamentals are available" do
      visit market_asset_path(voo.symbol)

      expect(page).to have_content("Sin datos fundamentales")
    end
  end

  describe "crypto" do
    let!(:btc) { create(:asset, :crypto, name: "Bitcoin", symbol: "BTC", currency: "USD", current_price: 67_250.00, change_percent_24h: 2.1) }

    before do
      create(:asset_fundamental, asset: btc, period_label: "CRYPTO_MARKET",
        metrics: { "market_cap" => "1310000000000", "total_volume_24h" => "28400000000" })
    end

    it "renders the Cripto chip and the Mercado tab, never the financial-statement tabs" do
      visit market_asset_path(btc.symbol)

      expect(page).to have_content("Cripto")
      expect(page).to have_button("Resumen")
      expect(page).to have_button("Mercado")
      expect(page).not_to have_button("Valoración")
      expect(page).not_to have_button("Dividendos")
      expect(page).not_to have_button("Estados financieros")
    end

    it "shows the CoinGecko data source caption (es-MX)" do
      visit market_asset_path(btc.symbol)

      expect(page).to have_content("Fuente: CoinGecko")
    end
  end

  describe "fixed income (CETE)" do
    let!(:cete) do
      create(:asset, :fixed_income, name: "CETES 28 días", symbol: "CETES_28D",
        yield_rate: 10.85, face_value: 10.0, maturity_date: 5.days.from_now.to_date)
    end

    it "renders the yield card instead of tabs (MXN throughout)" do
      visit market_asset_path(cete.symbol)

      expect(page).to have_content("CETES_28D")
      expect(page).to have_content("CETE")
      expect(page).to have_content("Detalle de la emisión")
      expect(page).to have_content("Avance al vencimiento")
      expect(page).to have_content("Simulación de inversión")
      expect(page).to have_content(/MXN\s/)
      expect(page).not_to have_button("Resumen")
    end

    it "shows the Banxico source caption and CETES-Directo subcopy" do
      visit market_asset_path(cete.symbol)

      expect(page).to have_content("Banxico")
      expect(page).to have_content("Cetes Directo")
    end
  end

  # S11 #144: "Acerca de la empresa / Ficha" 2-col block appended to the
  # Resumen tab. Adaptive per asset_type per the issue DoD:
  # stock → facts, ETF → facts, crypto → alt copy ("Acerca del activo"),
  # fixed_income → block renders nothing.
  describe "Acerca de la empresa / Ficha (#144)" do
    context "stock with an OVERVIEW row" do
      let!(:walmex) { create(:asset, name: "Wal-Mart de México", symbol: "WALMEX", asset_type: :stock, exchange: "BMV", currency: "MXN", country: "MX", current_price: 78.50) }

      before do
        create(:asset_fundamental, asset: walmex, period_label: "OVERVIEW",
          metrics: {
            "description" => "Wal-Mart de México opera Bodega Aurrera, Walmart y Sam's Club en México.",
            "sector"      => "Consumer Defensive",
            "industry"    => "Discount Stores",
            "country"     => "Mexico",
            "exchange"    => "BMV",
            "currency"    => "MXN"
          })
      end

      it "renders the description, the Ficha heading and the key facts" do
        visit market_asset_path(walmex.symbol)

        expect(page).to have_content("Acerca de la empresa")
        expect(page).to have_content("Wal-Mart de México opera Bodega Aurrera")
        expect(page).to have_content("Ficha")
        expect(page).to have_content("Sector")
        expect(page).to have_content("Consumer Defensive")
        expect(page).to have_content("Industria")
        expect(page).to have_content("Discount Stores")
        expect(page).to have_content("País")
        expect(page).to have_content("Mexico")
      end
    end

    context "ETF with an OVERVIEW row" do
      let!(:voo) { create(:asset, :etf, name: "Vanguard S&P 500 ETF", symbol: "VOO", currency: "USD", current_price: 540.12) }

      before do
        create(:asset_fundamental, asset: voo, period_label: "OVERVIEW",
          metrics: {
            "description" => "ETF que replica el índice S&P 500 de Vanguard.",
            "sector"      => "Equity",
            "country"     => "US",
            "exchange"    => "NYSE",
            "currency"    => "USD"
          })
      end

      it "renders the Ficha block with the ETF's descriptive fields" do
        visit market_asset_path(voo.symbol)

        expect(page).to have_content("Acerca de la empresa")
        expect(page).to have_content("ETF que replica el índice S&P 500")
        expect(page).to have_content("Ficha")
      end
    end

    context "crypto asset" do
      let!(:btc) { create(:asset, :crypto, name: "Bitcoin", symbol: "BTC", currency: "USD", current_price: 67_250.00) }

      before do
        create(:asset_fundamental, asset: btc, period_label: "CRYPTO_MARKET",
          metrics: { "market_cap" => "1310000000000" })
      end

      it "shows the alt copy 'Acerca del activo' instead of the company facts" do
        visit market_asset_path(btc.symbol)

        expect(page).to have_content("Acerca del activo")
        expect(page).to have_content("criptoactivo")
        expect(page).not_to have_content("Acerca de la empresa")
        expect(page).not_to have_content("Ficha")
      end
    end

    context "fixed_income (CETE)" do
      let!(:cete) do
        create(:asset, :fixed_income, name: "CETES 28 días", symbol: "CETES_28D",
          yield_rate: 10.85, face_value: 10.0, maturity_date: 5.days.from_now.to_date)
      end

      it "renders no Acerca de la empresa / Ficha block at all (yield card replaces tabs)" do
        visit market_asset_path(cete.symbol)

        expect(page).not_to have_content("Acerca de la empresa")
        expect(page).not_to have_content("Acerca del activo")
        expect(page).not_to have_content("Ficha")
      end
    end

    context "stock without an OVERVIEW row" do
      let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", asset_type: :stock, currency: "USD", current_price: 227.44) }

      it "renders the Ficha-not-available fallback copy in es-MX" do
        visit market_asset_path(apple.symbol)

        expect(page).to have_content("Ficha no disponible para este activo")
      end
    end
  end

  describe "recent observations panel" do
    let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", asset_type: :stock, currency: "USD", current_price: 227.44, country: "US") }

    before do
      create(:technical_observation, asset: apple, observation_type: "rsi_oversold_entered", observed_at: 2.hours.ago)
      create(:technical_observation, asset: apple, observation_type: "ma50_crossed_above", observed_at: 1.day.ago)
    end

    it "renders the es-MX panel with descriptive copy and a tag column" do
      visit market_asset_path(apple.symbol)

      expect(page).to have_content("Observaciones recientes")
      expect(page).to have_content("entró en zona de sobreventa")
      expect(page).to have_content("cruzó al alza su MA50")
      expect(page).to have_content("RSI")
      expect(page).to have_content("MEDIA MÓVIL")
    end
  end
end
