class CreateAlertEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_events do |t|
      t.references :alert_rule,   foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.string     :asset_symbol, null: false
      t.string     :message,      null: false
      t.integer    :event_status, null: false, default: 0
      t.datetime   :triggered_at, null: false

      t.timestamps
    end

    add_index :alert_events, [:user_id, :triggered_at]
    add_index :alert_events, :event_status
  end
end
