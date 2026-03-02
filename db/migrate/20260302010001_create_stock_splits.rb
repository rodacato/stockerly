class CreateStockSplits < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_splits do |t|
      t.references :asset, null: false, foreign_key: true
      t.date :ex_date, null: false
      t.integer :ratio_from, null: false
      t.integer :ratio_to, null: false

      t.timestamps
    end

    add_index :stock_splits, [ :asset_id, :ex_date ], unique: true
  end
end
