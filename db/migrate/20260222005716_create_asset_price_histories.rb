class CreateAssetPriceHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_price_histories do |t|
      t.references :asset,  null: false, foreign_key: true
      t.date       :date,   null: false
      t.decimal    :open,   precision: 15, scale: 4
      t.decimal    :high,   precision: 15, scale: 4
      t.decimal    :low,    precision: 15, scale: 4
      t.decimal    :close,  null: false, precision: 15, scale: 4
      t.bigint     :volume

      t.timestamps
    end

    add_index :asset_price_histories, [ :asset_id, :date ], unique: true
    add_index :asset_price_histories, :date
  end
end
