class CreateMarketHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :market_holidays do |t|
      t.date    :date,   null: false
      t.string  :name,   null: false
      t.integer :market, null: false, default: 0   # 0 BMV · 1 Banxico · 2 NYSE · 3 NASDAQ

      t.timestamps
    end

    add_index :market_holidays, [ :market, :date ], unique: true
    add_index :market_holidays, :date
  end
end
