class CreateMarketIndices < ActiveRecord::Migration[8.1]
  def change
    create_table :market_indices do |t|
      t.string  :name,           null: false
      t.string  :symbol,         null: false
      t.decimal :value,          precision: 15, scale: 4
      t.decimal :change_percent, precision: 8, scale: 4
      t.string  :exchange
      t.boolean :is_open,        null: false, default: false

      t.timestamps
    end

    add_index :market_indices, :symbol, unique: true
  end
end
