class CreateIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :integrations do |t|
      t.string   :provider_name,     null: false
      t.string   :provider_type,     null: false
      t.string   :api_key_encrypted
      t.integer  :connection_status, null: false, default: 0
      t.datetime :last_sync_at

      t.timestamps
    end

    add_index :integrations, :provider_name, unique: true
    add_index :integrations, :connection_status
  end
end
