class CreateMarketIndexHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :market_index_histories do |t|
      t.references :market_index, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :close_value, precision: 15, scale: 4, null: false

      t.timestamps
    end

    add_index :market_index_histories, [ :market_index_id, :date ], unique: true
  end
end
