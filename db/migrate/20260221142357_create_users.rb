class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :full_name,          null: false
      t.string  :email,              null: false
      t.string  :password_digest,    null: false
      t.string  :avatar_url
      t.integer :role,               null: false, default: 0
      t.integer :status,             null: false, default: 0
      t.boolean :is_verified,        null: false, default: false
      t.string  :preferred_currency, null: false, default: "USD"
      t.string  :password_reset_token
      t.datetime :password_reset_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :status
    add_index :users, :password_reset_token, unique: true
  end
end
