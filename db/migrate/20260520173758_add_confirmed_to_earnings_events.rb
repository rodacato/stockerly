class AddConfirmedToEarningsEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :earnings_events, :confirmed, :boolean, default: true, null: false
  end
end
