class AddIsDefaultToApiKeyPools < ActiveRecord::Migration[8.1]
  def change
    add_column :api_key_pools, :is_default, :boolean, default: false, null: false
    add_index :api_key_pools, [ :integration_id, :is_default ],
              unique: true,
              where: "is_default = true",
              name: "index_api_key_pools_on_integration_default"
  end
end
