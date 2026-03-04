class RemoveApiKeyEncryptedFromIntegrations < ActiveRecord::Migration[8.1]
  def up
    remove_column :integrations, :api_key_encrypted
  end

  def down
    add_column :integrations, :api_key_encrypted, :string
  end
end
