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

    it "offers Hoy's ? popovers a way into the drawer with the term written" do
      connect
      get dashboard_path

      expect(response.body).to include(I18n.t("assistant.launcher.con_la_frase"))
      expect(response.body).to include(CGI.escapeHTML(assistant_path(from: "panorama", q: I18n.t("dashboard.ayuda.veredicto.titulo"))))
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

  describe "the drawer" do
    before { connect }

    it "opens on Hoy's suggestions for the figures Hoy showed" do
      get assistant_path(from: "panorama", seen: "veredicto,vs_cetes"), headers: { "Turbo-Frame" => "assistant_sheet" }

      expect(response.body).to include(I18n.t("assistant.questions.new.desde", pantalla: I18n.t("nav.panorama")))
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
