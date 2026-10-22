require "rails_helper"

# Ajustes · Asistente (D167, #872 slice B). The provider is the one boundary
# stubbed: every request to it goes through WebMock.
RSpec.describe "Ajustes · Asistente", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let(:messages_url) { "https://api.anthropic.com/v1/messages" }
  let(:valid) { { base_url: "https://api.anthropic.com", api_key: "sk-ant-secret-a1b2", model: "claude-haiku-5-5" } }

  before { login_as(user) }

  def connection = Integration.find_by(provider_name: "Asistente")

  it "starts unconfigured, offering the Anthropic host and model" do
    get settings_assistant_path

    expect(response.body).to include(I18n.t("settings.assistants.show.estado.sin_configurar"))
    expect(response.body).to include("https://api.anthropic.com")
    expect(response.body).to include("claude-haiku-5-5")
  end

  it "saves the connection as Administration's row, unverified" do
    patch settings_assistant_path, params: { assistant: valid }

    expect(response).to redirect_to(settings_assistant_path)
    expect(connection.setting("base_url")).to eq("https://api.anthropic.com")
    expect(connection.setting("model")).to eq("claude-haiku-5-5")
    expect(connection.active_api_key).to eq("sk-ant-secret-a1b2")
    expect(connection).to be_disconnected
  end

  it "never renders the key, only its last four characters" do
    patch settings_assistant_path, params: { assistant: valid }
    get settings_assistant_path

    expect(response.body).not_to include("sk-ant-secret")
    expect(response.body).to include("a1b2")
  end

  it "keeps the saved key when the field comes back empty" do
    patch settings_assistant_path, params: { assistant: valid }
    patch settings_assistant_path, params: { assistant: valid.merge(api_key: "", model: "claude-sonnet-5-5") }

    expect(connection.active_api_key).to eq("sk-ant-secret-a1b2")
    expect(connection.setting("model")).to eq("claude-sonnet-5-5")
  end

  # Security review S1: the stored key must not follow a changed host unasked.
  it "asks for the key again before it goes to a new host" do
    patch settings_assistant_path, params: { assistant: valid }
    stub = stub_request(:post, "https://elsewhere.example.com/v1/messages")

    patch verify_settings_assistant_path, params: { assistant: valid.merge(base_url: "https://elsewhere.example.com", api_key: "") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("cambiaste el host")
    expect(stub).not_to have_been_requested
    expect(connection.setting("base_url")).to eq("https://api.anthropic.com")
  end

  it "refuses plain http to a public host, where the key would travel in the clear" do
    patch settings_assistant_path, params: { assistant: valid.merge(base_url: "http://example.com") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("debe usar https")
    expect(connection).to be_nil
  end

  it "accepts plain http inside the owner's network" do
    patch settings_assistant_path, params: { assistant: valid.merge(base_url: "http://192.168.1.20:11434") }

    expect(connection.setting("base_url")).to eq("http://192.168.1.20:11434")
  end

  describe "verifying" do
    # The outcome crosses to Administration as an event; the suite clears the
    # bus, so this loads the app's real wiring rather than restating it.
    before { load Rails.root.join("config/initializers/event_subscriptions.rb") }

    it "marks the connection as answering" do
      stub_request(:post, messages_url).to_return(status: 200, body: { content: [] }.to_json)

      patch verify_settings_assistant_path, params: { assistant: valid }
      follow_redirect!

      expect(connection).to be_connected
      expect(response.body).to include(I18n.t("settings.assistants.show.estado.conectada"))
    end

    it "says the key was refused" do
      stub_request(:post, messages_url).to_return(status: 401, body: { error: { message: "invalid x-api-key" } }.to_json)

      patch verify_settings_assistant_path, params: { assistant: valid }
      follow_redirect!

      expect(connection).to be_disconnected
      expect(response.body).to include(I18n.t("settings.assistants.show.fallas.unauthorized"))
    end

    it "says the host did not answer in time" do
      stub_request(:post, messages_url).to_timeout

      patch verify_settings_assistant_path, params: { assistant: valid }
      follow_redirect!

      expect(response.body).to include(I18n.t("settings.assistants.show.fallas.timeout"))
    end

    it "forgets a verified connection once the host changes" do
      stub_request(:post, messages_url).to_return(status: 200, body: { content: [] }.to_json)
      patch verify_settings_assistant_path, params: { assistant: valid }

      patch settings_assistant_path, params: { assistant: valid.merge(base_url: "https://shellm.example.com", api_key: "sk-other-c3d4") }

      expect(connection).to be_disconnected
    end
  end
end
