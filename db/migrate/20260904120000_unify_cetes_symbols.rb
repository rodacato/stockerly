class UnifyCetesSymbols < ActiveRecord::Migration[8.1]
  # AssetCatalog seeded `CETE28D` while SyncCetes created `CETES_28D`, so an
  # instance that ran the weekly Banxico sync holds two rows per term: the
  # catalogue's, static and disabled, and the sync's, carrying the live yield.
  # ADR-024 named the divergence and deferred it; #552 settles it on the
  # underscored spelling, which is the one the sync writes and the one the
  # maturity-progress block parses.
  PAIRS = {
    "CETE28D" => "CETES_28D",
    "CETE91D" => "CETES_91D",
    "CETE182D" => "CETES_182D",
    "CETE364D" => "CETES_364D"
  }.freeze

  # Rebuilt from the provider on the next sync, so the losing row's copies go
  # rather than merge.
  DERIVED_TABLES = %w[
    asset_fundamentals asset_price_histories dividends earnings_events
    financial_statements stock_splits technical_observations technical_readings
    trend_scores
  ].freeze

  def up
    PAIRS.each do |old_symbol, new_symbol|
      old_id = asset_id_for(old_symbol)
      next if old_id.nil?

      new_id = asset_id_for(new_symbol)
      new_id ? absorb(old_id, new_id, old_symbol) : rename(old_id, old_symbol, new_symbol)
      repoint_alert_rules(old_symbol, new_symbol)
    end
  end

  # The absorb branch destroys rows; a down that restored the symbol would not
  # bring back what it merged.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def asset_id_for(symbol)
    connection.select_value("SELECT id FROM assets WHERE symbol = #{quoted(symbol)}")
  end

  def rename(old_id, old_symbol, new_symbol)
    execute(<<~SQL.squish)
      UPDATE assets
      SET symbol = #{quoted(new_symbol)},
          former_symbols = array_append(former_symbols, #{quoted(old_symbol)})
      WHERE id = #{old_id}
    SQL
  end

  # Holdings move; a watchlist entry the reader already has on the surviving row
  # would collide on its unique index, so the duplicate goes first.
  def absorb(old_id, new_id, old_symbol)
    execute(<<~SQL.squish)
      DELETE FROM watchlist_items
      WHERE asset_id = #{old_id}
        AND user_id IN (SELECT user_id FROM watchlist_items WHERE asset_id = #{new_id})
    SQL

    %w[positions trades watchlist_items].each do |table|
      execute("UPDATE #{table} SET asset_id = #{new_id} WHERE asset_id = #{old_id}")
    end
    DERIVED_TABLES.each { |table| execute("DELETE FROM #{table} WHERE asset_id = #{old_id}") }

    execute("DELETE FROM assets WHERE id = #{old_id}")
    execute(<<~SQL.squish)
      UPDATE assets
      SET former_symbols = array_append(former_symbols, #{quoted(old_symbol)})
      WHERE id = #{new_id} AND NOT (#{quoted(old_symbol)} = ANY(former_symbols))
    SQL
  end

  def repoint_alert_rules(old_symbol, new_symbol)
    execute(<<~SQL.squish)
      UPDATE alert_rules
      SET asset_symbol = #{quoted(new_symbol)}
      WHERE asset_symbol = #{quoted(old_symbol)}
    SQL
  end

  def quoted(value) = connection.quote(value)
end
