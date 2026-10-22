# Chooses the cards a question reads, shows them, then streams prose over them
# and keeps it only if every figure in it came from those cards (ADR-031 §2).
class AssistantComposeJob < ApplicationJob
  queue_as :default

  FLUSH_EVERY = 0.3
  MAX_ANSWER = 4_000

  def perform(message_id)
    message = AssistantMessage.find_by(id: message_id)
    return unless message&.pending?

    connection = Administration::Queries::AssistantConnection.call
    return message.update!(status: :failed, failure_tag: "not_connected").then { broadcast(message) } unless connection

    cards = message.cards.map { |card| Assistant::Domain::Card.from_h(card) }.presence || choose_cards(message, connection)
    message.update!(cards: cards.map(&:to_h), status: :streaming)
    broadcast_cards(message)
    answer = stream(message, connection, cards)
    finish(message, answer, cards)
  rescue Assistant::Gateways::AnthropicMessages::Error
    message.update!(status: :failed, failure_tag: "provider_error")
    broadcast(message)
  end

  private

  # The planner picks from the registry; when it fails, picks nothing, or what
  # it picked holds no data, the deterministic selector answers instead.
  def choose_cards(message, connection)
    symbol = message.conversation.symbol
    holdings = connection[:read_holdings] == true
    planned = Assistant::Capabilities::Registry.new(holdings: holdings).cards(plan(message, connection, symbol, holdings))
    planned.presence || Assistant::Domain::ContextSelector.call(question: message.question, symbol: symbol, holdings: holdings)
  end

  def plan(message, connection, symbol, holdings)
    gateway = Assistant::Gateways::AnthropicMessages.new(base_url: connection[:base_url], api_key: connection[:api_key].to_s,
                                                         model: connection[:planner_model] || connection[:model])
    reply = gateway.complete(system: Assistant::Domain::Planner.system(symbol, holdings: holdings),
                             messages: [ { role: "user", content: asked(message) } ])
    Assistant::Domain::Planner.steps(reply, holdings: holdings)
  rescue Assistant::Gateways::AnthropicMessages::Error => e
    Rails.logger.info("[assistant] planner failed, using the selector: #{e.message}")
    []
  end

  # Earlier questions only, never their answers or cards: a follow-up resolves,
  # and the numbers gate still sees only this turn's reads (D172).
  def asked(message)
    earlier = message.conversation.messages.where(created_at: ...message.created_at).last(Assistant::Domain::Prompt::EARLIER)
    Assistant::Domain::Prompt.question(message.question, earlier: earlier.map(&:question))
  end

  def stream(message, connection, cards)
    gateway = Assistant::Gateways::AnthropicMessages.new(base_url: connection[:base_url], api_key: connection[:api_key].to_s,
                                                         model: connection[:model])
    answer = +""
    flushed_at = 0.0
    gateway.stream(system: Assistant::Domain::Prompt.system(cards), messages: [ { role: "user", content: asked(message) } ]) do |text|
      answer << text
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next if now - flushed_at < FLUSH_EVERY

      flushed_at = now
      raise Assistant::Gateways::AnthropicMessages::Error, "answer too long" if answer.length > MAX_ANSWER

      message.answer = shown(answer, cards)
      broadcast(message) if message.answer
    end
    answer
  end

  # What the reader may see mid-stream: the gate runs on every flush, so a
  # figure the cards do not hold never reaches the screen. The last word is
  # held back, since a number may still be arriving.
  def shown(answer, cards)
    @held ||= false
    settled = answer.sub(/\S*\z/, "")
    @held ||= !Assistant::Domain::NumbersGate.call(answer: settled, context: Assistant::Domain::Prompt.context_text(cards)).ok?
    @held ? nil : settled
  end

  def finish(message, answer, cards)
    gate = Assistant::Domain::NumbersGate.call(answer: answer, context: Assistant::Domain::Prompt.context_text(cards))
    if gate.ok?
      message.update!(status: :answered, answer: answer)
    else
      message.update!(status: :discarded, answer: nil, failure_tag: "invented_figures")
    end
    broadcast(message)
  end

  def broadcast_cards(message)
    Turbo::StreamsChannel.broadcast_replace_to("assistant", message.conversation.token, target: "assistant_message_#{message.id}",
                                                                     partial: "assistant/questions/message", locals: { message: message })
  end

  def broadcast(message)
    Turbo::StreamsChannel.broadcast_replace_to("assistant", message.conversation.token, target: "assistant_answer_#{message.id}",
                                                                     partial: "assistant/questions/answer", locals: { message: message })
  end
end
