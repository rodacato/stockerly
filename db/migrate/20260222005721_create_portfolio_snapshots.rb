class CreatePortfolioSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_snapshots do |t|
      t.references :portfolio,      null: false, foreign_key: true, index: false
      t.date       :date,           null: false
      t.decimal    :total_value,    null: false, precision: 15, scale: 2
      t.decimal    :cash_value,     null: false, precision: 15, scale: 2
      t.decimal    :invested_value, null: false, precision: 15, scale: 2

      t.timestamps
    end

    add_index :portfolio_snapshots, [ :portfolio_id, :date ], unique: true
    add_index :portfolio_snapshots, :date
  end
end
