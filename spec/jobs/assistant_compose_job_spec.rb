require "rails_helper"

# The provider is the one boundary stubbed; its SSE stream is replayed as the
# Messages API sends it.
RSpec.describe AssistantComposeJob do
  let(:url) { "https://api.anthropic.com/v1/messages" }
  let(:conversation) { AssistantConversation.create!(token: "t1") }
  let(:message) do
    conversation.messages.create!(question: "¿Qué significa el RSI?", model: "claude-haiku-5-5",
                                  cards: [ { kind: "reading", title: "RSI (14) · NVDA", body: "En zona de sobrecompra", figure: "72.4", source: nil } ])
  end

  before do
    Integration.create!(provider_name: "Asistente", provider_type: "Assistant", connection_status: :connected,
                        api_key_encrypted: "sk-test", settings: { "base_url" => "https://api.anthropic.com", "model" => "claude-haiku-5-5" })
  end

  def stream(*chunks)
    events = chunks.map do |text|
      %(event: content_block_delta\ndata: #{ { type: "content_block_delta", index: 0, delta: { type: "text_delta", text: text } }.to_json }\n\n)
    end
    stub_request(:post, url).to_return(status: 200, body: events.join, headers: { "Content-Type" => "text/event-stream" })
  end

  it "keeps prose whose every figure came from the cards" do
    stream("El RSI de NVDA está en 72.4 [1], ", "en zona de sobrecompra.")

    described_class.perform_now(message.id)

    expect(message.reload).to be_answered
    expect(message.answer).to eq("El RSI de NVDA está en 72.4 [1], en zona de sobrecompra.")
  end

  it "discards prose that states a figure the cards do not hold" do
    stream("El RSI está en 72.4 [1] y subirá a 80.")

    described_class.perform_now(message.id)

    expect(message.reload).to be_discarded
    expect(message.answer).to be_nil
    expect(message.cards).not_to be_empty
  end

  it "records a provider failure without an answer" do
    stub_request(:post, url).to_return(status: 401, body: { type: "error", error: { message: "invalid x-api-key" } }.to_json)

    described_class.perform_now(message.id)

    expect(message.reload).to be_failed
    expect(message.failure_tag).to eq("provider_error")
  end

  it "does nothing to a message already answered" do
    message.update!(status: :answered, answer: "ya")

    described_class.perform_now(message.id)

    expect(a_request(:post, url)).not_to have_been_made
  end
end
