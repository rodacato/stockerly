class AssistantConversation < ApplicationRecord
  has_many :messages, -> { order(:created_at) }, class_name: "AssistantMessage", inverse_of: :conversation, dependent: :delete_all
end
