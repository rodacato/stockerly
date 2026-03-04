class AddSettingsToIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :integrations, :settings, :jsonb, default: {}, null: false
  end
end
