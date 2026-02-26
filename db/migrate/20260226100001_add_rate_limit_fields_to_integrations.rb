class AddRateLimitFieldsToIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :integrations, :max_requests_per_minute, :integer, default: nil
    add_column :integrations, :minute_calls, :integer, default: 0, null: false
    add_column :integrations, :minute_reset_at, :datetime
  end
end
