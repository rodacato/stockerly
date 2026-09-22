require "rails_helper"

RSpec.describe "Admin Integrations", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  before { login_as(admin) }

  describe "PATCH /admin/integrations/:id" do
    let!(:integration) { create(:integration, provider_name: "Alpaca", daily_call_limit: 500) }

    it "updates the integration rate limits" do
      patch admin_integration_path(integration), params: {
        integration: { daily_call_limit: 1000, max_requests_per_minute: 10 }
      }

      expect(response).to redirect_to(admin_integrations_path)
      expect(flash[:notice]).to eq("Integración actualizada.")
      expect(integration.reload.daily_call_limit).to eq(1000)
      expect(integration.reload.max_requests_per_minute).to eq(10)
    end

    it "clears a limit back to unlimited when the field is submitted empty" do
      integration.update!(max_requests_per_minute: 10)

      patch admin_integration_path(integration), params: {
        integration: { daily_call_limit: 500, max_requests_per_minute: "" }
      }

      expect(integration.reload.max_requests_per_minute).to be_nil
      expect(integration.reload.daily_call_limit).to eq(500)
    end
  end

  describe "GET /admin/integrations" do
    it "asks Alpaca for both halves of its credential while it has none" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: nil)

      get admin_integrations_path

      expect(response.body).to include("KEY_ID:SECRET")
    end

    # The registry is the one list. A row in `integrations` that no source
    # claims is not a source, and drawing it invited the second list the
    # screen exists to remove.
    it "lists only what the registry claims" do
      create(:integration, provider_name: "Finnhub")
      create(:integration, provider_name: "Ghost provider")

      get admin_integrations_path

      expect(response.body).to include("Finnhub")
      expect(response.body).not_to include("Ghost provider")
    end

    # D123: an instance that has not migrated yet still holds the row.
    it "does not offer a retired provider whose row outlived it" do
      create(:integration, provider_name: "Alpha Vantage", api_key_encrypted: "k")
      create(:integration, provider_name: "FMP", api_key_encrypted: "k")

      get admin_integrations_path

      expect(response.body).not_to include("Alpha Vantage")
      expect(response.body).not_to include("FMP")
      expect(response.body).not_to include("31 de agosto de 2025")
    end

    it "says a source is missing its key, that the instance owns that, and what it costs" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: nil, requires_api_key: true)

      get admin_integrations_path

      expect(response.body).to include("Sin API key")
      expect(response.body).to include("Es tu instancia")
      expect(response.body).to include("dividendos y splits de tus posiciones estadounidenses")
    end

    # The distinction the screen exists for: our counter versus their refusal.
    it "separates our exhausted quota from the provider refusing us" do
      create(:integration, provider_name: "Finnhub", api_key_encrypted: "k", requires_api_key: true,
                           daily_call_limit: 25, daily_api_calls: 25, calls_reset_at: Time.current)
      create(:integration, provider_name: "Yahoo Finance", requires_api_key: false,
                           last_failure_tag: "rate_limited", last_failure_at: 1.hour.ago)

      get admin_integrations_path

      expect(response.body).to include("Es tu cuota")
      expect(response.body).to include("Es el proveedor")
    end



    # D146: near-limit is a property of a working source, not a fifth state.
    # The header counts it in words, so the card says it in words too — the
    # amber bar stays, but it stops being the only thing that carries it.
    describe "a connected source close to its own limit" do
      before do
        create(:integration, provider_name: "Finnhub", api_key_encrypted: "k", requires_api_key: true,
                             daily_call_limit: 100, daily_api_calls: 80, calls_reset_at: Time.current)
      end

      it "says so in words beside the figure the warning is about" do
        get admin_integrations_path

        expect(response.body).to include("80 / 100 hoy · cerca del límite")
      end

      it "leaves the state column at its four honest values" do
        get admin_integrations_path

        expect(response.body).to include(I18n.t("admin.integrations.index.estado.connected"))
        expect(response.body).not_to include(I18n.t("admin.integrations.index.estado.no_quota"))
        expect(MarketData::Domain::SourceCatalogue::STATES.size).to eq(4)
      end
    end

    # Negative: an exhausted source already says "Sin cuota" and carries its
    # own reason strip. Adding "cerca del límite" there would report the state
    # that stopped it as the state that is about to.
    it "does not qualify a source whose quota already ran out" do
      create(:integration, provider_name: "Finnhub", api_key_encrypted: "k", requires_api_key: true,
                           daily_call_limit: 25, daily_api_calls: 25, calls_reset_at: Time.current)

      get admin_integrations_path

      expect(response.body).to include(I18n.t("admin.integrations.index.estado.no_quota"))
      expect(response.body).not_to include("· cerca del límite")
    end

    it "leaves a comfortable source's quota line unqualified" do
      create(:integration, provider_name: "Finnhub", api_key_encrypted: "k", requires_api_key: true,
                           daily_call_limit: 100, daily_api_calls: 10, calls_reset_at: Time.current)

      get admin_integrations_path

      expect(response.body).to include("10 / 100 hoy")
      expect(response.body).not_to include("· cerca del límite")
    end

    it "shows the masked key instead of the format once Alpaca has one" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKTEST123:secret9999")

      get admin_integrations_path

      expect(response.body).not_to include("KEY_ID:SECRET")
      expect(response.body).to include("9999")
    end
  end

  describe "the source panel's controls" do
    let!(:integration) { create(:integration, provider_name: "Alpaca") }

    before { get admin_integrations_path }

    # Verificar was hand-rolled on bg-primary-muted, which made the one
    # read-only control the loudest thing in the panel.
    it "gives Verificar the same treatment as Guardar" do
      verificar = Capybara.string(response.body)
                          .find("button", text: I18n.t("admin.integrations.index.verificar"))

      expect(verificar[:class]).to eq(ApplicationController.helpers.button_classes(:secondary, :sm))
    end

    # The field's only name was its placeholder, which also carries the format
    # hint Alpaca needs — and both vanish on the first keystroke.
    it "names the API key field, as both limit fields are named" do
      expect(Capybara.string(response.body))
        .to have_field(I18n.t("admin.integrations.index.api_key"), type: "password")
    end

    # Delete sat 8px from Guardar in the same gap-2 row as the two reversible
    # controls.
    it "separates the destructive control from the reversible ones" do
      expect(response.body).to include(%(<div class="flex flex-wrap items-center gap-6">))
      expect(response.body).to include(%(<form class="inline-flex ml-auto"))
    end
  end

  describe "DELETE /admin/integrations/:id" do
    let!(:integration) { create(:integration, provider_name: "Old Provider") }

    it "deletes the integration" do
      expect {
        delete admin_integration_path(integration)
      }.to change(Integration, :count).by(-1)

      expect(response).to redirect_to(admin_integrations_path)
      expect(flash[:notice]).to eq("Integración eliminada.")
    end
  end

  describe "POST /admin/integrations" do
    it "says the provider is connected" do
      post admin_integrations_path, params: {
        integration: { provider_name: "Finnhub", provider_type: "market_data" }
      }

      expect(response).to redirect_to(admin_integrations_path)
      expect(flash[:notice]).to eq("Integración conectada.")
    end
  end

  describe "POST /admin/integrations/:id/refresh_sync" do
    let!(:integration) { create(:integration, provider_name: "Alpaca") }

    it "says the sync was queued" do
      post refresh_sync_admin_integration_path(integration)

      expect(flash[:notice]).to eq("Sincronización de la integración programada.")
    end
  end
end
