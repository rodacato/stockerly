class CreateEmailEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :email_events do |t|
      t.string   :email,       null: false
      t.string   :event_type,  null: false
      t.string   :message_id
      t.datetime :occurred_at, null: false
      t.jsonb    :raw_payload, null: false, default: {}
      t.timestamps
    end

    add_index :email_events, :email
    add_index :email_events, :event_type
    add_index :email_events, :message_id
    add_index :email_events, [ :message_id, :event_type ],
              unique: true,
              where:  "message_id IS NOT NULL",
              name:   "index_email_events_on_message_and_type"
  end
end
