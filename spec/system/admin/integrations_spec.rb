require "rails_helper"

RSpec.describe "Admin integrations (Lumen)", type: :system do
  before { driven_by :rack_test }

  let!(:admin) do
    create(:user, :admin,
           email: "admin@test.com", password: "password123",
           onboarded_at: Time.current, email_verified_at: Time.current)
  end
  let!(:portfolio) { create(:portfolio, user: admin) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "admin@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders the header in es-MX" do
    create(:integration, provider_name: "Polygon.io", provider_type: "Stocks")
    visit admin_integrations_path

    expect(page).to have_content("Integraciones")
    expect(page).to have_content("De dónde salen tus precios")
    expect(page).to have_content("ese límite es el que reparte el presupuesto de Rastreados")
    expect(page).to have_content("Polygon.io")
  end

  it "renders the empty state when no integrations exist" do
    Integration.destroy_all
    visit admin_integrations_path

    expect(page).to have_content("No hay fuentes configuradas")
    expect(page).to have_content("Agrégalas desde el wizard inicial")
    expect(page).to have_link("Configurar integraciones", href: onboarding_integrations_path)
  end

  it "shows the Activa pill when the integration is connected with a default key" do
    create(:integration, provider_name: "Polygon.io", provider_type: "Stocks",
                         connection_status: :connected, daily_call_limit: 500, max_requests_per_minute: 5)
    visit admin_integrations_path

    expect(page).to have_content("Activa")
    # The usage bar the artboard draws, over counters the table already had
    # and no screen ever showed.
    expect(page).to have_content("0 / 5 por minuto")
    expect(page).to have_content("1 llave")
  end

  it "shows the Pausada pill and the add-key callout when no keys are configured" do
    integration = create(:integration, :keyless, provider_name: "Finnhub", provider_type: "Sentiment")
    integration.update!(requires_api_key: true)
    visit admin_integrations_path

    expect(page).to have_content("Pausada")
    expect(page).to have_content("sin llave")
  end

  it "shows the Error pill when disconnected" do
    create(:integration, :disconnected, provider_name: "Yahoo Finance", provider_type: "Backup")
    visit admin_integrations_path

    expect(page).to have_content("Error")
  end

  it "offers the masked last-4 as the key field's placeholder" do
    create(:integration, provider_name: "Polygon.io", provider_type: "Stocks", api_key_encrypted: "abcdefghij9999")
    visit admin_integrations_path

    expect(page).to have_field("integration[api_key_encrypted]", placeholder: "••••••••••••9999", visible: :all)
  end

  it "deletes an integration with the trash icon" do
    integration = create(:integration, provider_name: "OldProvider", provider_type: "Stocks")

    expect {
      page.driver.submit :delete, admin_integration_path(integration), {}
    }.to change(Integration, :count).by(-1)
  end
end
