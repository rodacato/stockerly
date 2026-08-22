class DropInviteCodes < ActiveRecord::Migration[8.1]
  # Beta invite-gate for multi-user registration — deleted in the 2.0 evolve
  # (single-user bootstraps via first-boot setup). Reversible.
  def change
    drop_table :invite_codes do |t|
      t.string "code", null: false
      t.datetime "created_at", null: false
      t.bigint "created_by_user_id", null: false
      t.datetime "expires_at", null: false
      t.string "note"
      t.datetime "updated_at", null: false
      t.datetime "used_at"
      t.bigint "used_by_user_id"
      t.index [ "code" ], name: "index_invite_codes_on_code", unique: true
      t.index [ "created_by_user_id" ], name: "index_invite_codes_on_created_by_user_id"
      t.index [ "expires_at" ], name: "index_invite_codes_on_expires_at"
      t.index [ "used_by_user_id" ], name: "index_invite_codes_on_used_by_user_id"
    end
  end
end
