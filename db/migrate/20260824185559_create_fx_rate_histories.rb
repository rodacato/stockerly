class CreateFxRateHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :fx_rate_histories do |t|
      t.string :base_currency, null: false
      t.string :quote_currency, null: false
      t.date :rate_date, null: false
      t.decimal :rate, precision: 15, scale: 6, null: false
      t.string :source, null: false, default: "unknown"

      t.timestamps
    end

    add_index :fx_rate_histories,
              [ :base_currency, :quote_currency, :rate_date ],
              unique: true,
              name: "index_fx_rate_histories_on_pair_and_date"
    add_index :fx_rate_histories, :rate_date
  end
end
