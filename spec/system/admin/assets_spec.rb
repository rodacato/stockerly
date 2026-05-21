require "rails_helper"

RSpec.describe "Admin · Catálogo de activos", type: :system do
  before { driven_by :rack_test }

  let!(:admin) do
    create(:user, :admin, :email_verified, email: "admin@stockerly.mx",
                                            password: "password123",
                                            onboarded_at: Time.current,
                                            full_name: "Adrian Romero")
  end
  let!(:admin_portfolio) { create(:portfolio, user: admin) }

  let!(:aapl)    { create(:asset, symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", country: "US", asset_type: :stock, price_updated_at: 4.minutes.ago) }
  let!(:walmex)  { create(:asset, :mexican, symbol: "WALMEX", name: "Walmart de México", price_updated_at: 12.minutes.ago) }
  let!(:btc)     { create(:asset, :crypto, symbol: "BTC", name: "Bitcoin", exchange: "COINGECKO", country: nil, price_updated_at: 1.minute.ago) }
  let!(:cete28)  { create(:asset, :fixed_income, symbol: "CETE-28D", name: "CETES 28 días", price_updated_at: 14.minutes.ago) }
  let!(:nvda)    { create(:asset, :sync_issue, symbol: "NVDA", name: "NVIDIA Corp.", exchange: "NASDAQ", country: "US", price_updated_at: 3.hours.ago) }
  let!(:gfnorteo) { create(:asset, :mexican, symbol: "GFNORTEO", name: "Grupo Banorte", price_updated_at: 30.hours.ago) }
  let!(:eth)     { create(:asset, :crypto, :disabled, symbol: "ETH", name: "Ethereum", exchange: "COINGECKO", country: nil) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: admin.email
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders the header band with both CTAs in es-MX" do
    visit admin_assets_path

    expect(page).to have_content("Catálogo de activos")
    expect(page).to have_content("Activos")
    expect(page).to have_content("Crea, edita y sincroniza activos rastreados por Stockerly.")
    expect(page).to have_button("Sincronizar todos")
    expect(page).to have_button("Nuevo activo")
  end

  it "lists assets with their type chip, market, country, and status pill" do
    visit admin_assets_path

    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("AAPL")
    expect(page).to have_content("Bitcoin")
    expect(page).to have_content("WALMEX")
    expect(page).to have_content("CETE-28D")

    # asset type labels (es-MX)
    expect(page).to have_content("accion")
    expect(page).to have_content("cripto")
    expect(page).to have_content("renta fija")

    # market codes
    expect(page).to have_content("NASDAQ")
    expect(page).to have_content("BMV")
    expect(page).to have_content("COINGECKO")
    expect(page).to have_content("Banxico")
  end

  it "renders status pills for active, paused, and error states" do
    visit admin_assets_path
    expect(page).to have_content("Activo")
    expect(page).to have_content("Pausado")
    expect(page).to have_content("Error")
  end

  it "filters by tipo" do
    visit admin_assets_path(type: "crypto")
    expect(page).to have_content("Bitcoin")
    expect(page).to have_content("Ethereum")
    expect(page).not_to have_content("Apple Inc.")
  end

  it "filters by estado — pausados" do
    visit admin_assets_path(status: "disabled")
    expect(page).to have_content("Ethereum")
    expect(page).not_to have_content("Apple Inc.")
  end

  it "filters by mercado — BMV" do
    visit admin_assets_path(market: "BMV")
    expect(page).to have_content("Walmart de México")
    expect(page).to have_content("Grupo Banorte")
    expect(page).not_to have_content("Apple Inc.")
  end

  it "filters by mercado — Otros (unknown exchanges)" do
    create(:asset, symbol: "XPTO", name: "Otro activo", exchange: "OTHER_EX", country: "US")
    visit admin_assets_path(market: "Otros")
    expect(page).to have_content("Otro activo")
    expect(page).not_to have_content("Apple Inc.")
  end

  it "shows the Limpiar filtros affordance when a filter is active" do
    visit admin_assets_path(type: "crypto")
    expect(page).to have_link("Limpiar filtros", href: admin_assets_path)
  end

  it "preserves the active tipo + estado + mercado chips when the search form submits" do
    visit admin_assets_path(type: "stock", status: "active", market: "NASDAQ")
    # Regression for #137 — search form must carry filters via hidden fields.
    expect(page).to have_field("type", type: "hidden", with: "stock")
    expect(page).to have_field("status", type: "hidden", with: "active")
    expect(page).to have_field("market", type: "hidden", with: "NASDAQ")
  end

  it "shows the inline-edit form structure for each row" do
    visit admin_assets_path
    # Inline-edit forms are rendered (hidden) for every row; verify the markup
    # so future regressions catch a broken reveal pattern.
    expect(page).to have_css("tbody[data-controller='reveal']", minimum: 7)
    expect(page).to have_css("[data-reveal-target='content']", minimum: 7, visible: false)
  end

  it "toggles asset sync status via the row action" do
    expect(aapl.sync_status).to eq("active")
    page.driver.submit :patch, toggle_status_admin_asset_path(aapl), {}
    visit admin_assets_path
    expect(aapl.reload.sync_status).to eq("disabled")
  end

  it "creates a new asset via the form post" do
    page.driver.post admin_assets_path, asset: {
      symbol: "GOOGL", name: "Alphabet Inc.", asset_type: "stock",
      country: "US", exchange: "NASDAQ", sector: "Technology"
    }

    visit admin_assets_path
    expect(page).to have_content("Alphabet Inc.")
    expect(page).to have_content("GOOGL")
  end

  it "renders the empty state copy when there are no assets" do
    Asset.destroy_all
    visit admin_assets_path

    expect(page).to have_content("Aún no hay activos en el catálogo.")
    expect(page).to have_content("Crea el primer activo para empezar a sincronizar precios.")
    expect(page).to have_button("Crear primer activo")
  end
end
