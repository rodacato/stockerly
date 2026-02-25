class AddApiBudgetToIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :integrations, :daily_api_calls, :integer, default: 0, null: false
    add_column :integrations, :daily_call_limit, :integer, default: 500, null: false
    add_column :integrations, :calls_reset_at, :datetime
  end
end
