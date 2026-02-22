class CreateAlertRules < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_rules do |t|
      t.references :user,            null: false, foreign_key: true
      t.string     :asset_symbol,    null: false
      t.integer    :condition,       null: false
      t.decimal    :threshold_value, null: false, precision: 15, scale: 4
      t.integer    :status,          null: false, default: 0

      t.timestamps
    end

    add_index :alert_rules, [:user_id, :status]
    add_index :alert_rules, :asset_symbol
  end
end
