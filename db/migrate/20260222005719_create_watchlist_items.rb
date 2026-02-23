class CreateWatchlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :watchlist_items do |t|
      t.references :user,        null: false, foreign_key: true, index: false
      t.references :asset,       null: false, foreign_key: true, index: false
      t.decimal    :entry_price, precision: 15, scale: 4

      t.timestamps
    end

    add_index :watchlist_items, [ :user_id, :asset_id ], unique: true
  end
end
