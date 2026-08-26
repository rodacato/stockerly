class AddLastFailureToIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :integrations, :last_failure_tag, :string
    add_column :integrations, :last_failure_at, :datetime
  end
end
