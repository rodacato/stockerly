# Writes the prose over the cards a question already has, streaming it into
# the page, and keeps it only if every figure in it came from those cards
# (ADR-031 §2: discarded, not repaired).
class AssistantComposeJob < ApplicationJob
  queue_as :default

  FLUSH_EVERY = 0.3

  def perform(message_id)
    message = AssistantMessage.find_by(id: message_id)
    return unless message&.pending?

    connection = Administration::Queries::AssistantConnection.call
    return message.update!(status: :failed, failure_tag: "not_connected").then { broadcast(message) } unless connection

    cards = message.cards.map { |card| Assistant::Domain::Card.from_h(card) }
    message.update!(status: :streaming)
    answer = stream(message, connection, cards)
    finish(message, answer, cards)
  rescue Assistant::Gateways::AnthropicMessages::Error
    message.update!(status: :failed, failure_tag: "provider_error")
    broadcast(message)
  end

  private

  def stream(message, connection, cards)
    gateway = Assistant::Gateways::AnthropicMessages.new(base_url: connection[:base_url], api_key: connection[:api_key].to_s,
                                                         model: connection[:model])
    answer = +""
    flushed_at = 0.0
    gateway.stream(system: Assistant::Domain::Prompt.system(cards), messages: [ { role: "user", content: message.question } ]) do |text|
      answer << text
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next if now - flushed_at < FLUSH_EVERY

      flushed_at = now
      message.answer = answer
      broadcast(message)
    end
    answer
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

  def broadcast(message)
    Turbo::StreamsChannel.broadcast_replace_to("assistant", message.conversation.token, target: "assistant_answer_#{message.id}",
                                                                     partial: "assistant/questions/answer", locals: { message: message })
  end
end
