class DropUserActivities < ActiveRecord::Migration[8.1]
  # Beta usage-audit telemetry (#172): write-only, nothing in the UI reads it.
  # No place in the single-user product — dropped in the 2.0 evolve. Reversible.
  def change
    drop_table :user_activities do |t|
      t.string "action", null: false
      t.datetime "created_at", null: false
      t.datetime "occurred_at", null: false
      t.jsonb "params", default: {}, null: false
      t.datetime "updated_at", null: false
      t.bigint "user_id", null: false
      t.index ["action"], name: "index_user_activities_on_action"
      t.index ["occurred_at"], name: "index_user_activities_on_occurred_at"
      t.index ["user_id", "action", "occurred_at"], name: "index_user_activities_on_user_action_occurred"
      t.index ["user_id"], name: "index_user_activities_on_user_id"
    end
  end
end
