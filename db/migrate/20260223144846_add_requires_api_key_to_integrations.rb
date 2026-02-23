class AddRequiresApiKeyToIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :integrations, :requires_api_key, :boolean, default: true, null: false
  end
end
