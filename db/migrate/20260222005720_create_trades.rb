class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :portfolio,      null: false, foreign_key: true
      t.references :asset,          null: false, foreign_key: true
      t.references :position,       foreign_key: true
      t.integer    :side,           null: false
      t.decimal    :shares,         null: false, precision: 15, scale: 6
      t.decimal    :price_per_share, null: false, precision: 15, scale: 4
      t.decimal    :total_amount,   null: false, precision: 15, scale: 2
      t.decimal    :fee,            null: false, precision: 10, scale: 2, default: 0
      t.string     :currency,       null: false, default: "USD"
      t.datetime   :executed_at,    null: false

      t.timestamps
    end

    add_index :trades, [:portfolio_id, :asset_id]
    add_index :trades, :executed_at
    add_index :trades, :side
  end
end
