module Assistant
  module UseCases
    # Records the question and hands it to the job that chooses its cards and writes the prose.
    class AskQuestion < ApplicationUseCase
      def call(question:, token:, symbol: nil, screen: "hoy")
        question = question.to_s.squish
        return Failure([ :validation, { question: [ :too_long ] } ]) if question.length > AssistantMessage::MAX_QUESTION

        connection = Administration::Queries::AssistantConnection.call
        return Failure([ :not_connected ]) unless connection && connection[:status] == :connected

        conversation = AssistantConversation.find_or_create_by!(token: token) do |created|
          created.symbol = symbol.presence&.upcase
          created.screen = screen
        end
        message = conversation.messages.create(question: question, model: connection[:model])
        return Failure([ :validation, message.errors.to_hash ]) unless message.persisted?

        AssistantComposeJob.perform_later(message.id)
        Success(message)
      end
    end
  end
end
