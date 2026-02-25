class CreateApiKeyPools < ActiveRecord::Migration[8.1]
  def change
    create_table :api_key_pools do |t|
      t.references :integration, null: false, foreign_key: true
      t.string :api_key_encrypted, null: false
      t.integer :daily_calls, default: 0, null: false
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end
  end
end
