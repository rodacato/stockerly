class AddNameToApiKeyPools < ActiveRecord::Migration[8.1]
  def change
    add_column :api_key_pools, :name, :string, null: false, default: "Default"
  end
end
