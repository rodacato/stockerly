module Assistant
  module UseCases
    # Records the question with its cards already chosen, so the reader sees
    # them before the model is called; the prose follows from a job.
    class AskQuestion < ApplicationUseCase
      def call(question:, token:, symbol: nil, screen: "hoy")
        connection = Administration::Queries::AssistantConnection.call
        return Failure([ :not_connected ]) unless connection && connection[:status] == :connected

        conversation = AssistantConversation.find_or_create_by!(token: token) do |created|
          created.symbol = symbol.presence&.upcase
          created.screen = screen
        end
        cards = Domain::ContextSelector.call(question: question, symbol: conversation.symbol)
        message = conversation.messages.create(question: question.to_s.squish, cards: cards.map(&:to_h), model: connection[:model])
        return Failure([ :validation, message.errors.to_hash ]) unless message.persisted?

        AssistantComposeJob.perform_later(message.id)
        Success(message)
      end
    end
  end
end
