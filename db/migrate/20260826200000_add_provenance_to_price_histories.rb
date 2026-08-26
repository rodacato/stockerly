class AddProvenanceToPriceHistories < ActiveRecord::Migration[8.1]
  LEGACY_SOURCE = "legacy:unknown".freeze

  def up
    %i[asset_price_histories market_index_histories].each do |table|
      add_column table, :source, :string
      add_column table, :interval, :string, default: "1d", null: false
      add_column table, :status, :string, default: "confirmed", null: false
      add_column table, :as_of, :datetime
      add_column table, :fetched_at, :datetime
    end

    # Rows written before provenance existed genuinely have none. An explicit
    # sentinel records that, which is recoverable; a null would be read later as
    # "nobody set this", which is not. created_at is when we fetched them.
    execute <<~SQL.squish
      UPDATE asset_price_histories SET source = '#{LEGACY_SOURCE}', fetched_at = created_at WHERE source IS NULL
    SQL
    execute <<~SQL.squish
      UPDATE market_index_histories SET source = '#{LEGACY_SOURCE}', fetched_at = created_at WHERE source IS NULL
    SQL

    change_column_null :asset_price_histories, :source, false
    change_column_null :market_index_histories, :source, false

    # One row per day becomes one row per day per interval, which is what makes
    # an intraday series storable beside a daily one.
    remove_index :asset_price_histories, column: %i[asset_id date], unique: true
    add_index :asset_price_histories, %i[asset_id date interval], unique: true

    remove_index :market_index_histories, column: %i[market_index_id date], unique: true
    add_index :market_index_histories, %i[market_index_id date interval], unique: true
  end

  def down
    remove_index :asset_price_histories, column: %i[asset_id date interval], unique: true
    add_index :asset_price_histories, %i[asset_id date], unique: true
    remove_index :market_index_histories, column: %i[market_index_id date interval], unique: true
    add_index :market_index_histories, %i[market_index_id date], unique: true

    %i[asset_price_histories market_index_histories].each do |table|
      remove_column table, :source
      remove_column table, :interval
      remove_column table, :status
      remove_column table, :as_of
      remove_column table, :fetched_at
    end
  end
end
