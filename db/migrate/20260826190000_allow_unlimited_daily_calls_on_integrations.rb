class AllowUnlimitedDailyCallsOnIntegrations < ActiveRecord::Migration[8.1]
  def change
    change_column_null :integrations, :daily_call_limit, true
  end
end
