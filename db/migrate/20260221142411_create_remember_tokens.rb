class CreateRememberTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :remember_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string   :token_digest,  null: false
      t.datetime :expires_at,    null: false
      t.datetime :last_used_at
      t.string   :ip_address
      t.string   :user_agent

      t.timestamps
    end

    add_index :remember_tokens, :token_digest, unique: true
    add_index :remember_tokens, [ :user_id, :expires_at ]
  end
end
