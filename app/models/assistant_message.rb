# One question and what came back: the cards selected before the model was
# called, and the prose it wrote over them, kept only if the numbers gate let
# it through (ADR-031 §2).
class AssistantMessage < ApplicationRecord
  belongs_to :conversation, class_name: "AssistantConversation", foreign_key: :assistant_conversation_id, inverse_of: :messages

  enum :status, { pending: "pending", streaming: "streaming", answered: "answered", discarded: "discarded", failed: "failed" },
       default: :pending

  validates :question, presence: true, length: { maximum: 500 }
end
