class CreateEarningsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :earnings_events do |t|
      t.references :asset,         null: false, foreign_key: true
      t.date       :report_date,   null: false
      t.integer    :timing,        null: false, default: 0
      t.decimal    :estimated_eps, precision: 10, scale: 4
      t.decimal    :actual_eps,    precision: 10, scale: 4

      t.timestamps
    end

    add_index :earnings_events, :report_date
    add_index :earnings_events, [:asset_id, :report_date], unique: true
  end
end
