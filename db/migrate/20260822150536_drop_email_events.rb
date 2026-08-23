class DropEmailEvents < ActiveRecord::Migration[8.1]
  # Beta-only email delivery tracking (Resend webhook). No place in the
  # single-user product — dropped in the 2.0 evolve. Reversible for safety.
  def change
    drop_table :email_events do |t|
      t.datetime "created_at", null: false
      t.string "email", null: false
      t.string "event_type", null: false
      t.string "message_id"
      t.datetime "occurred_at", null: false
      t.jsonb "raw_payload", default: {}, null: false
      t.datetime "updated_at", null: false
      t.index [ "email" ], name: "index_email_events_on_email"
      t.index [ "event_type" ], name: "index_email_events_on_event_type"
      t.index [ "message_id", "event_type" ], name: "index_email_events_on_message_and_type", unique: true, where: "(message_id IS NOT NULL)"
      t.index [ "message_id" ], name: "index_email_events_on_message_id"
    end
  end
end
