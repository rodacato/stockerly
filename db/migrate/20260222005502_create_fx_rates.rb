class CreateFxRates < ActiveRecord::Migration[8.1]
  def change
    create_table :fx_rates do |t|
      t.string   :base_currency,  null: false
      t.string   :quote_currency, null: false
      t.decimal  :rate,           null: false, precision: 15, scale: 6
      t.datetime :fetched_at,     null: false

      t.timestamps
    end

    add_index :fx_rates, [ :base_currency, :quote_currency ], unique: true
    add_index :fx_rates, :fetched_at
  end
end
