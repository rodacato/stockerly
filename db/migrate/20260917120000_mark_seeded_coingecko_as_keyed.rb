class MarkSeededCoingeckoAsKeyed < ActiveRecord::Migration[8.1]
  # The gateway refuses to run without a Demo key, but rows created from the
  # earlier defaults were recorded as keyless, so syncs were attempted and failed.
  def up
    execute("UPDATE integrations SET requires_api_key = TRUE WHERE provider_name = 'CoinGecko'")
  end

  # The earlier value cannot be told apart from a row that was already keyed.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
