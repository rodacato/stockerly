class MoveApiKeyOntoIntegrations < ActiveRecord::Migration[8.1]
  # ADR-015: one key per provider. The pool was the only place a key lived, so
  # retiring it means moving the key rather than deleting a feature.
  class MigrationIntegration < ActiveRecord::Base
    self.table_name = "integrations"
    encrypts :api_key_encrypted
  end

  class MigrationPoolKey < ActiveRecord::Base
    self.table_name = "api_key_pools"
    encrypts :api_key_encrypted
  end

  def up
    add_column :integrations, :api_key_encrypted, :string

    MigrationIntegration.reset_column_information
    MigrationPoolKey.reset_column_information

    MigrationIntegration.find_each do |integration|
      key = MigrationPoolKey
              .where(integration_id: integration.id, enabled: true)
              .order(is_default: :desc, daily_calls: :asc)
              .first
      next if key.nil? || key.api_key_encrypted.blank?

      integration.update!(api_key_encrypted: key.api_key_encrypted)
    end

    drop_table :api_key_pools
  end

  def down
    create_table :api_key_pools do |t|
      t.string :api_key_encrypted, null: false
      t.integer :daily_calls, default: 0, null: false
      t.boolean :enabled, default: true, null: false
      t.bigint :integration_id, null: false
      t.boolean :is_default, default: false, null: false
      t.string :name, default: "Default", null: false
      t.timestamps
    end
    add_index :api_key_pools, :integration_id
    add_index :api_key_pools, [ :integration_id, :is_default ],
      name: "index_api_key_pools_on_integration_default", unique: true, where: "(is_default = true)"

    MigrationIntegration.reset_column_information
    MigrationPoolKey.reset_column_information

    MigrationIntegration.where.not(api_key_encrypted: nil).find_each do |integration|
      MigrationPoolKey.create!(
        integration_id: integration.id,
        api_key_encrypted: integration.api_key_encrypted,
        name: "Default",
        is_default: true,
        enabled: true
      )
    end

    remove_column :integrations, :api_key_encrypted
  end
end
