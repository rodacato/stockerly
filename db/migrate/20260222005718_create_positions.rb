class CreatePositions < ActiveRecord::Migration[8.1]
  def change
    create_table :positions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :asset,     null: false, foreign_key: true
      t.decimal    :shares,    null: false, precision: 15, scale: 6
      t.decimal    :avg_cost,  null: false, precision: 15, scale: 4
      t.string     :currency,  null: false, default: "USD"
      t.integer    :status,    null: false, default: 0
      t.datetime   :opened_at
      t.datetime   :closed_at

      t.timestamps
    end

    add_index :positions, :status
    add_index :positions, [ :portfolio_id, :asset_id, :status ]
  end
end
