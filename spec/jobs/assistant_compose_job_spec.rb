require "rails_helper"

# The provider is the one boundary stubbed; its SSE stream is replayed as the
# Messages API sends it.
RSpec.describe AssistantComposeJob do
  include ActionCable::TestHelper

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

  # F2: a stream with no prose is a reply that never came, not an answer.
  it "records an empty reply as the provider failing, so it can be asked again" do
    stream("  ")

    described_class.perform_now(message.id)

    expect(message.reload).to be_failed
    expect(message.failure_tag).to eq("empty_answer")
    expect(message.answer).to be_nil
  end

  it "records a provider failure without an answer" do
    stub_request(:post, url).to_return(status: 401, body: { type: "error", error: { message: "invalid x-api-key" } }.to_json)

    described_class.perform_now(message.id)

    expect(message.reload).to be_failed
    expect(message.failure_tag).to eq("provider_error")
  end

  # Security review: the gate runs on every flush, not only at the end, so an
  # invented figure is never on screen even while the answer streams.
  it "never shows a figure the cards do not hold, even mid-stream" do
    stream("Llegará a 80 pronto ", "según nadie.")
    described_class.perform_now(message.id)

    shown = broadcasts("assistant:#{conversation.token}")
    expect(shown).not_to be_empty
    expect(shown.join).not_to include("Llegará a 80")
    expect(message.reload).to be_discarded
  end

  it "keeps none of the prose a provider failure cut off" do
    error = %(event: error\ndata: #{ { type: "error", error: { message: "overloaded" } }.to_json }\n\n)
    content = %(event: content_block_delta\ndata: #{ { type: "content_block_delta", index: 0, delta: { type: "text_delta", text: "El RSI es 72.4 [1] y luego " } }.to_json }\n\n)
    stub_request(:post, url).to_return(status: 200, body: content + error)

    described_class.perform_now(message.id)

    expect(message.reload).to be_failed
    expect(message.answer).to be_nil
  end

  it "fails an answer the token limit cut off mid-sentence" do
    content = %(event: content_block_delta\ndata: #{ { type: "content_block_delta", index: 0, delta: { type: "text_delta", text: "El RSI es 72.4 [1] y en zona de" } }.to_json }\n\n)
    stop = %(event: message_delta\ndata: #{ { type: "message_delta", delta: { stop_reason: "max_tokens" } }.to_json }\n\n)
    stub_request(:post, url).to_return(status: 200, body: content + stop)

    described_class.perform_now(message.id)

    expect(message.reload).to be_failed
    expect(message.answer).to be_nil
  end

  it "fails the message, so it can be asked again, when anything else breaks mid-answer" do
    stream("El RSI de NVDA está en 72.4 [1].")
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_call_original
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with(anything, anything, hash_including(partial: "assistant/questions/message")).and_raise("render failed")

    expect { described_class.perform_now(message.id) }.to raise_error("render failed")
    expect(message.reload).to be_failed
  end

  it "treats a malformed stream as the provider failing, not a stuck answer" do
    stub_request(:post, url).to_return(status: 200, body: "event: content_block_delta\ndata: {not json\n\n")

    described_class.perform_now(message.id)

    expect(message.reload).to be_failed
  end

  it "does not ask a provider the owner disconnected after the question was queued" do
    Integration.find_by(provider_type: "Assistant").update!(connection_status: :disconnected)
    stream("hola")

    described_class.perform_now(message.id)

    expect(a_request(:post, url)).not_to have_been_made
    expect(message.reload.failure_tag).to eq("not_connected")
  end

  it "does nothing to a message already answered" do
    message.update!(status: :answered, answer: "ya")

    described_class.perform_now(message.id)

    expect(a_request(:post, url)).not_to have_been_made
  end

  describe "choosing the cards" do
    let!(:asset) { create(:asset, symbol: "NVDA", name: "NVIDIA", current_price: 110, price_updated_at: Time.current) }
    let(:conversation) { AssistantConversation.create!(token: "t2", symbol: "NVDA") }
    let(:message) { conversation.messages.create!(question: "¿Cómo va la empresa?", model: "claude-haiku-5-5") }

    before do
      create(:technical_reading, asset: asset, readings: { "close" => 110.0, "rsi" => 72.4 })
      create(:asset_fundamental, asset: asset)
      prose = { type: "content_block_delta", index: 0, delta: { type: "text_delta", text: "Va bien." } }.to_json
      stub_request(:post, url).with(body: hash_including("stream" => true))
                              .to_return(status: 200, headers: { "Content-Type" => "text/event-stream" },
                                         body: "event: content_block_delta\ndata: #{prose}\n\n")
    end

    def planner_answers(*reads, status: 200)
      text = reads.map { |name, input| { read: name, **input } }.to_json
      stub_request(:post, url).with { |request| !JSON.parse(request.body).key?("stream") }
                              .to_return(status: status, body: { content: [ { type: "text", text: text } ] }.to_json)
    end

    def kinds = message.reload.cards.pluck("kind")

    it "reads what the planner chose, from the registry" do
      planner_answers([ "asset.fundamentals", { symbol: "nvda" } ])

      described_class.perform_now(message.id)

      expect(kinds).to eq(%w[fundamentals])
    end

    it "shows the cards before the prose, in their own broadcast" do
      planner_answers([ "asset.fundamentals", { symbol: "NVDA" } ])

      described_class.perform_now(message.id)

      expect(broadcasts("assistant:#{conversation.token}").first).to include("assistant_message_#{message.id}")
    end

    it "reads the owner's holdings the planner chose, with the switch on" do
      row = Integration.find_by(provider_name: "Asistente")
      row.update!(settings: row.settings.merge("read_holdings" => true))
      portfolio = create(:portfolio, user: create(:user, onboarded_at: Time.current))
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100, status: :open)
      planner_answers([ "portfolio.positions", { symbol: "NVDA" } ])

      described_class.perform_now(message.id)

      expect(kinds).to eq(%w[position])
    end

    it "ignores a holdings read while the switch is off, and falls back to the selector" do
      planner_answers([ "portfolio.positions", { symbol: "NVDA" } ])

      described_class.perform_now(message.id)

      expect(kinds).to eq(%w[quote fundamentals])
    end

    it "falls back to the selector when the provider cannot plan" do
      planner_answers(status: 400)

      described_class.perform_now(message.id)

      expect(kinds).to eq(%w[quote fundamentals])
      expect(message).not_to be_failed
    end

    it "falls back when the planner reads nothing" do
      planner_answers

      described_class.perform_now(message.id)

      expect(kinds).to eq(%w[quote fundamentals])
    end

    it "asks the planner with the planner model when one is set" do
      Integration.find_by(provider_name: "Asistente").update!(settings: { "base_url" => "https://api.anthropic.com", "model" => "claude-sonnet-5-5", "planner_model" => "claude-haiku-5-5" })
      planner = planner_answers([ "asset.fundamentals", { symbol: "NVDA" } ])

      described_class.perform_now(message.id)

      expect(planner.with(body: hash_including("model" => "claude-haiku-5-5"))).to have_been_requested
    end
  end
  # D172: a follow-up carries the earlier questions, never their answers or
  # cards, so a figure from an earlier turn cannot reach this one.
  it "sends the earlier questions of the conversation, and nothing they answered" do
    conversation.messages.create!(question: "¿Cómo está el mercado?", answer: "El IPC sube 0.6 [1].", status: :answered,
                                  created_at: 2.minutes.ago, cards: [ { kind: "market", title: "Contexto de mercado", body: "IPC 0.6" } ])
    stream("El RSI de NVDA está en 72.4 [1].")

    described_class.perform_now(message.id)

    sent = ->(request) { JSON.parse(request.body) }
    expect(a_request(:post, url).with do |request|
      content = sent.call(request)["messages"].sole["content"]
      content.include?("- ¿Cómo está el mercado?") && content.include?("Pregunta: ¿Qué significa el RSI?") &&
        content.exclude?("0.6") && sent.call(request)["system"].exclude?("Contexto de mercado")
    end).to have_been_made
  end

  it "does not repeat a failed question as an earlier one when it is retried" do
    conversation.messages.create!(question: "¿Qué significa el RSI?", status: :failed, created_at: 2.minutes.ago)
    stream("El RSI de NVDA está en 72.4 [1].")

    described_class.perform_now(message.id)

    expect(a_request(:post, url).with { |request| JSON.parse(request.body)["messages"] == [ { "role" => "user", "content" => "¿Qué significa el RSI?" } ] })
      .to have_been_made.at_least_once
  end

  it "asks the first question of a conversation as it was written" do
    stream("El RSI de NVDA está en 72.4 [1].")

    described_class.perform_now(message.id)

    expect(a_request(:post, url).with { |request| JSON.parse(request.body)["messages"] == [ { "role" => "user", "content" => "¿Qué significa el RSI?" } ] })
      .to have_been_made
  end
end
