class CreateDividendPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :dividend_payments do |t|
      t.references :portfolio,   null: false, foreign_key: true, index: false
      t.references :dividend,    null: false, foreign_key: true, index: false
      t.decimal    :shares_held, null: false, precision: 15, scale: 6
      t.decimal    :total_amount, null: false, precision: 15, scale: 2
      t.datetime   :received_at

      t.timestamps
    end

    add_index :dividend_payments, [:portfolio_id, :dividend_id], unique: true
  end
end
