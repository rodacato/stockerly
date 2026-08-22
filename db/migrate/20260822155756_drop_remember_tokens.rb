class DropRememberTokens < ActiveRecord::Migration[8.1]
  # "Remember me" persistent-login tokens + the active-sessions UI. A single-user
  # self-hosted instance uses plain session auth; persistent login, if wanted, is a
  # session-cookie lifetime, not a token table. Dropped in the 2.0 evolve. Reversible.
  def change
    drop_table :remember_tokens do |t|
      t.datetime "created_at", null: false
      t.datetime "expires_at", null: false
      t.string "ip_address"
      t.datetime "last_used_at"
      t.string "token_digest", null: false
      t.datetime "updated_at", null: false
      t.string "user_agent"
      t.bigint "user_id", null: false
      t.index ["token_digest"], name: "index_remember_tokens_on_token_digest", unique: true
      t.index ["user_id", "expires_at"], name: "index_remember_tokens_on_user_id_and_expires_at"
      t.index ["user_id"], name: "index_remember_tokens_on_user_id"
    end
  end
end
