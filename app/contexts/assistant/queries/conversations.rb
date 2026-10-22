module Assistant
  module Queries
    # The assistant's own record read back (D172): the conversations to list,
    # newest question first, and one conversation to continue.
    module Conversations
      RECENT = 30

      def self.recent
        ids = AssistantMessage.group(:assistant_conversation_id).order(Arel.sql("MAX(created_at) DESC"))
                              .limit(RECENT).pluck(:assistant_conversation_id)
        AssistantConversation.where(id: ids).includes(:messages).index_by(&:id).values_at(*ids)
      end

      def self.find(token) = AssistantConversation.includes(:messages).find_by(token: token.to_s)
    end
  end
end
