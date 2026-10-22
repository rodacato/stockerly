require "rails_helper"

RSpec.describe "Assistant questions", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user, onboarded_at: Time.current) }

  before { login_as(user) }

  def connect(status: :connected)
    Integration.create!(provider_name: "Asistente", provider_type: "Assistant", connection_status: status,
                        api_key_encrypted: "sk-test", settings: { "base_url" => "https://api.anthropic.com", "model" => "claude-haiku-5-5" })
  end

  it "sends an unconnected owner to connect a model first" do
    get assistant_path

    expect(response.body).to include(I18n.t("assistant.questions.new.sin_conexion"))
    expect(response.body).not_to include('id="assistant_form"')
  end

  it "subscribes the page to its conversation before the first question" do
    connect
    get assistant_path(symbol: "nvda")

    expect(response.body).to include("turbo-cable-stream-source")
    expect(response.body).to include(I18n.t("assistant.questions.new.sobre", symbol: "NVDA"))
  end

  it "shows the question at once and leaves choosing the cards and the prose to the job" do
    connect

    expect do
      post assistant_questions_path, params: { question: { question: "¿Qué significa el RSI?", token: "abc", symbol: "" } },
                                     as: :turbo_stream
    end.to have_enqueued_job(AssistantComposeJob)

    expect(response.body).to include("¿Qué significa el RSI?")
    expect(response.body).to include(I18n.t("assistant.questions.answer.buscando"))
    expect(AssistantMessage.last.cards).to eq([])
    expect(AssistantConversation.find_by(token: "abc").messages.count).to eq(1)
  end

  it "keeps asking in the same conversation under the same token" do
    connect
    2.times { post assistant_questions_path, params: { question: { question: "¿Qué es el RSI?", token: "abc" } }, as: :turbo_stream }

    expect(AssistantConversation.where(token: "abc").sole.messages.count).to eq(2)
  end

  it "refuses an oversized question before choosing any card" do
    connect

    post assistant_questions_path, params: { question: { question: "RSI " * 200, token: "abc" } }, as: :turbo_stream

    expect(response).to have_http_status(:unprocessable_content)
    expect(AssistantConversation.count).to eq(0)
  end

  it "asks nothing of a connection that never answered" do
    connect(status: :disconnected)

    post assistant_questions_path, params: { question: { question: "¿Qué es el RSI?", token: "abc" } }

    expect(response).to redirect_to(settings_assistant_path)
    expect(AssistantMessage.count).to eq(0)
  end
  describe "earlier conversations (D172)" do
    let!(:older) { AssistantConversation.create!(token: "old", symbol: "NVDA", screen: "activos") }
    let!(:newer) { AssistantConversation.create!(token: "new") }

    before do
      connect
      older.messages.create!(question: "¿Qué es el RSI?", created_at: 2.days.ago, status: :answered, answer: "Mide el impulso [1].",
                             cards: [ { "kind" => "glossary", "title" => "RSI (14)", "body" => "Mide el impulso", "figure" => nil, "source" => nil } ])
      newer.messages.create!(question: "¿Cómo está el mercado?", created_at: 1.hour.ago)
    end

    it "lists them, the one asked last first" do
      get assistant_conversations_path

      expect(response.body.index("¿Cómo está el mercado?")).to be < response.body.index("¿Qué es el RSI?")
      expect(response.body).to include(assistant_path(c: "old"))
    end

    it "reopens one where it stopped, under its own token, screen and symbol" do
      get assistant_path(c: "old")

      expect(response.body).to include("¿Qué es el RSI?", "Mide el impulso", I18n.t("assistant.questions.new.sobre", symbol: "NVDA"))
      expect(response.body).to include('value="old"')
      expect(response.body).not_to include("assistant_suggestions")
    end

    it "starts a fresh conversation for a token it does not know" do
      get assistant_path(c: "nope")

      expect(response.body).not_to include('value="nope"', "¿Qué es el RSI?")
    end

    it "lists nothing when nothing was asked" do
      AssistantConversation.destroy_all

      get assistant_conversations_path

      expect(response.body).to include(I18n.t("assistant.conversations.index.vacio"))
    end
  end
end
