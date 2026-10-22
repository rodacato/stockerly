class CreateAssistantConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :assistant_conversations do |t|
      t.string :token, null: false, index: { unique: true }
      t.string :symbol
      t.string :screen, null: false, default: "hoy"
      t.timestamps
    end

    create_table :assistant_messages do |t|
      t.references :assistant_conversation, null: false, foreign_key: { on_delete: :cascade }
      t.string :question, null: false
      t.jsonb :cards, null: false, default: []
      t.text :answer
      t.string :status, null: false, default: "pending"
      t.string :failure_tag
      t.string :model
      t.timestamps
    end
  end
end
