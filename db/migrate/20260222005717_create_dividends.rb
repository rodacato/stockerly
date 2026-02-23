class CreateDividends < ActiveRecord::Migration[8.1]
  def change
    create_table :dividends do |t|
      t.references :asset,            null: false, foreign_key: true
      t.date       :ex_date,          null: false
      t.date       :pay_date
      t.decimal    :amount_per_share, null: false, precision: 10, scale: 4
      t.string     :currency,         null: false, default: "USD"

      t.timestamps
    end

    add_index :dividends, [ :asset_id, :ex_date ], unique: true
    add_index :dividends, :ex_date
  end
end
