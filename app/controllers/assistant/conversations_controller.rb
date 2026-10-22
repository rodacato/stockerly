module Assistant
  # /assistant/conversations: the earlier conversations, each one reopened
  # where it stopped (D172).
  class ConversationsController < AuthenticatedController
    def index
      @conversations = Assistant::Queries::Conversations.recent
      query = params.permit(:from, :symbol)
      @context = { from: query[:from].presence_in(QuestionsController::SCREENS), symbol: query[:symbol].presence&.upcase }.compact
    end
  end
end
