require "rails_helper"

# Velita and the drawer she opens (D166, D167, #872 slice C2).
RSpec.describe "Velita", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let(:launcher) { I18n.t("assistant.launcher.abrir") }

  before { login_as(user) }

  def connect(status: :connected, show_velita: true)
    Integration.create!(provider_name: "Asistente", provider_type: "Assistant", connection_status: status, api_key_encrypted: "sk-test",
                        settings: { "base_url" => "https://api.anthropic.com", "model" => "claude-haiku-5-5", "show_velita" => show_velita })
  end

  describe "where she appears" do
    it "stays away until a connection exists" do
      get dashboard_path

      expect(response.body).not_to include(launcher)
      expect(response.body).not_to include("assistant_sheet")
    end

    it "stays away while switched off, even with a connection that answers" do
      connect(show_velita: false)
      get dashboard_path

      expect(response.body).not_to include(launcher)
    end

    it "stays away when the connection stops answering, even switched on" do
      connect(status: :disconnected)
      get dashboard_path

      expect(response.body).not_to include(launcher)
    end

    it "opens the drawer from Hoy, saying which screen she was opened on" do
      connect
      get dashboard_path

      expect(response.body).to include(launcher)
      expect(response.body).to match(%r{href="/assistant\?from=panorama[^"]*"})
      expect(response.body).to include('data-turbo-frame="assistant_sheet"')
    end

    it "carries the asset's symbol from its page" do
      connect
      create(:asset, symbol: "NVDA", name: "NVIDIA Corp.")
      get market_asset_path("NVDA")

      expect(response.body).to include(%(href="#{CGI.escapeHTML(assistant_path(from: "activos", symbol: "NVDA"))}"))
    end

    it "says Señales is where she was opened, not its tab" do
      connect
      get signals_path

      expect(response.body).to include(CGI.escapeHTML(assistant_path(from: "senales")))

      get assistant_path(from: "senales"), headers: { "Turbo-Frame" => "assistant_sheet" }
      expect(response.body).to include(I18n.t("assistant.questions.new.desde", pantalla: "Señales", posiciones: I18n.t("assistant.questions.new.no_ve_tus_posiciones")))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("assistant.questions.new.sugerencias.senales.semana")))
    end

    it "offers Hoy's ? popovers a way into the drawer with the term written" do
      connect
      get dashboard_path

      expect(response.body).to include(I18n.t("assistant.launcher.con_la_frase"))
      expect(response.body).to include(CGI.escapeHTML(assistant_path(from: "panorama", q: I18n.t("dashboard.ayuda.veredicto.titulo"), via: "help", figure: "veredicto")))
    end
  end

  describe "the switch" do
    it "is saved on Administration's row and changes nothing else" do
      connect(show_velita: false)

      patch velita_settings_assistant_path, params: { show_velita: true }, as: :json

      expect(response).to have_http_status(:ok)
      row = Integration.find_by(provider_name: "Asistente")
      expect(row.setting("show_velita")).to be(true)
      expect(row.setting("model")).to eq("claude-haiku-5-5")
    end

    it "turns her off" do
      connect

      patch velita_settings_assistant_path, params: { show_velita: false }, as: :json
      get dashboard_path

      expect(response.body).not_to include(launcher)
    end

    it "has nothing to switch before a connection is configured" do
      patch velita_settings_assistant_path, params: { show_velita: true }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "cannot be turned on from the screen until the connection answers" do
      connect(status: :disconnected, show_velita: false)
      get settings_assistant_path

      expect(response.body).to include(I18n.t("settings.assistants.show.velita_sin_conexion"))
      expect(response.body).to match(/role="switch"[^>]*disabled/)
    end
  end

  # D173: five colours that carry no verdict.
  describe "her colour" do
    it "starts índigo, and the one picked is pressed" do
      connect
      get settings_assistant_path

      expect(response.body).to include(%(aria-pressed="true" aria-label="#{I18n.t("settings.assistants.show.colores.indigo")}"))
      expect(response.body).to include(%(aria-pressed="false" aria-label="#{I18n.t("settings.assistants.show.colores.cielo")}"))
    end

    it "paints her everywhere she appears" do
      connect

      patch appearance_settings_assistant_path, params: { velita_colour: "cielo" }
      expect(response).to redirect_to(settings_assistant_path)
      get dashboard_path

      expect(response.body).to include("text-chart-2")
      expect(response.body).not_to include("text-chart-1")
    end

    it "refuses a colour outside the five" do
      connect

      patch appearance_settings_assistant_path, params: { velita_colour: "verde" }

      expect(Integration.find_by(provider_name: "Asistente").setting("velita_colour")).to be_nil
    end

    it "has no appearance to change before a connection is configured" do
      get settings_assistant_path
      expect(response.body).not_to include(I18n.t("settings.assistants.show.apariencia"))

      patch appearance_settings_assistant_path, params: { velita_colour: "cielo" }
      expect(response).to have_http_status(:not_found)
    end
  end

  # ADR-031's 2026-10-22 amendment.
  describe "the holdings switch" do
    it "starts off, naming the host the holdings would go to" do
      connect
      get settings_assistant_path

      expect(response.body).to include(I18n.t("settings.assistants.show.posiciones_desc", host: "Anthropic"))
      expect(response.body).to match(/role="switch" aria-checked="false" aria-label="#{I18n.t("settings.assistants.show.posiciones")}"/)
      expect(Integration.find_by(provider_name: "Asistente").setting("read_holdings")).to be_nil
    end

    it "is saved on Administration's row and changes nothing else" do
      connect

      patch holdings_settings_assistant_path, params: { read_holdings: true }, as: :json

      expect(response).to have_http_status(:ok)
      row = Integration.find_by(provider_name: "Asistente")
      expect(row.setting("read_holdings")).to be(true)
      expect(row.setting("show_velita")).to be(true)
      expect(Administration::Queries::AssistantConnection.call[:read_holdings]).to be(true)
    end

    it "reads anything but true as off" do
      connect

      patch holdings_settings_assistant_path, params: { read_holdings: "true" }, as: :json

      expect(Administration::Queries::AssistantConnection.call[:read_holdings]).to be(false)
    end

    it "tells the drawer and the connection what is sent while it is on" do
      connect
      row = Integration.find_by(provider_name: "Asistente")
      row.update!(settings: row.settings.merge("read_holdings" => true))

      get assistant_path(symbol: "NVDA")
      expect(response.body).to include(I18n.t("assistant.questions.new.sobre", symbol: "NVDA", posiciones: I18n.t("assistant.questions.new.lee_tus_posiciones")))

      get settings_assistant_path
      expect(response.body).to include(I18n.t("settings.assistants.show.conexion_con_posiciones"))
      expect(response.body).not_to include(I18n.t("settings.assistants.show.conexion_desc"))
    end

    it "has nothing to switch before a connection is configured" do
      patch holdings_settings_assistant_path, params: { read_holdings: true }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "cannot be turned on from the screen until the connection answers" do
      connect(status: :disconnected)
      get settings_assistant_path

      expect(response.body).to include(I18n.t("settings.assistants.show.posiciones_sin_conexion"))
      expect(response.body).to match(/aria-label="#{I18n.t("settings.assistants.show.posiciones")}"\s+disabled/)
    end
  end

  describe "the drawer" do
    before { connect }

    it "opens on Hoy's suggestions for the figures Hoy showed" do
      get assistant_path(from: "panorama", seen: "veredicto,vs_cetes"), headers: { "Turbo-Frame" => "assistant_sheet" }

      expect(response.body).to include(I18n.t("assistant.questions.new.desde", pantalla: I18n.t("nav.panorama"), posiciones: I18n.t("assistant.questions.new.no_ve_tus_posiciones")))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("assistant.questions.new.sugerencias.panorama.cetes")))
      expect(response.body).not_to include(CGI.escapeHTML(I18n.t("assistant.questions.new.sugerencias.panorama.resultados")))
    end

    it "suggests nothing it cannot point at on an empty Hoy" do
      get assistant_path(from: "panorama", seen: "veredicto"), headers: { "Turbo-Frame" => "assistant_sheet" }

      expect(response.body).not_to include('id="assistant_suggestions"')
      expect(response.body).not_to include(I18n.t("assistant.questions.new.de_lo_que_ves"))
    end

    it "tells Velita which of Hoy's figures were on screen" do
      get dashboard_path

      expect(response.body).to include(CGI.escapeHTML(assistant_path(from: "panorama", seen: "veredicto")))
    end

    it "opens with the question already written instead of suggestions" do
      get assistant_path(from: "panorama", q: "Contra CETES"), headers: { "Turbo-Frame" => "assistant_sheet" }

      expect(response.body).to include(%(value="Contra CETES"))
      expect(response.body).not_to include('id="assistant_suggestions"')
    end

    it "records the screen it was asked from, and nothing it does not know" do
      post assistant_questions_path, params: { question: { question: "¿Qué es el RSI?", token: "t-from", screen: "panorama" } }, as: :turbo_stream
      post assistant_questions_path, params: { question: { question: "¿Qué es el RSI?", token: "t-junk", screen: "<script>" } }, as: :turbo_stream

      expect(AssistantConversation.find_by(token: "t-from").screen).to eq("panorama")
      expect(AssistantConversation.find_by(token: "t-junk").screen).to eq("hoy")
    end
  end
end
