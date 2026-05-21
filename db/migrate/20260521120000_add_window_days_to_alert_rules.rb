class AddWindowDaysToAlertRules < ActiveRecord::Migration[8.1]
  def change
    # window_days backs the date-based rule types (e.g. dividend_ex_date)
    # where the user picks "N days before the event". Optional — price /
    # RSI / volume rules keep working with threshold_value only.
    add_column :alert_rules, :window_days, :integer
  end
end
