class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :assets do |t|
      t.string  :name,               null: false
      t.string  :symbol,             null: false
      t.integer :asset_type,         null: false, default: 0
      t.string  :sector
      t.string  :exchange
      t.string  :data_source
      t.integer :sync_status,        null: false, default: 0
      t.decimal :current_price,      precision: 15, scale: 4
      t.decimal :change_percent_24h, precision: 8, scale: 4
      t.decimal :market_cap,         precision: 20, scale: 2
      t.decimal :pe_ratio,           precision: 10, scale: 4
      t.decimal :div_yield,          precision: 8, scale: 4
      t.bigint  :volume
      t.bigint  :shares_outstanding
      t.datetime :price_updated_at

      t.timestamps
    end

    add_index :assets, :symbol, unique: true
    add_index :assets, :asset_type
    add_index :assets, :sector
    add_index :assets, :exchange
    add_index :assets, :sync_status
    add_index :assets, [ :asset_type, :sector ]
  end
end
