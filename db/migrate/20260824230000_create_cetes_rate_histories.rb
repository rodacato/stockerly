# D28: the Consolidado's benchmark reinvests CETES from the start of the
# period, which is ~13 different rates across a year. `fetch_auctions` asks
# Banxico for the latest auction only, and SyncCetes persists none of them —
# it just updates the Asset's discount price.
class CreateCetesRateHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :cetes_rate_histories do |t|
      t.string  :term, null: false
      t.date    :auction_date, null: false
      t.decimal :yield_rate, precision: 8, scale: 4, null: false
      t.string  :source, null: false, default: "banxico"

      t.timestamps
    end

    add_index :cetes_rate_histories, [ :term, :auction_date ], unique: true,
              name: "index_cetes_rate_histories_on_term_and_date"
    add_index :cetes_rate_histories, :auction_date
  end
end
