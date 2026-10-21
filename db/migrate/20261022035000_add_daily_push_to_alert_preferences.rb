class AddDailyPushToAlertPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :alert_preferences, :daily_push, :boolean, default: false, null: false
  end
end
