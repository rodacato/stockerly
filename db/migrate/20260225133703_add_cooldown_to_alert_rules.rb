class AddCooldownToAlertRules < ActiveRecord::Migration[8.1]
  def change
    add_column :alert_rules, :last_triggered_at, :datetime
    add_column :alert_rules, :cooldown_minutes, :integer, default: 60
  end
end
