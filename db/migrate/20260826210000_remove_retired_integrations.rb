class RemoveRetiredIntegrations < ActiveRecord::Migration[8.1]
  # Providers whose gateway, registration and directory entry are all gone.
  # CNN went with the Fear & Greed retirement and its row outlived it; Polygon
  # goes with the Alpaca and Finnhub migration.
  #
  # A row without a gateway is a key nobody can spend, on a screen whose job is
  # configuration — it reads as a source that could be reconnected.
  RETIRED = [ "Polygon.io", "CNN" ].freeze

  def up
    execute("DELETE FROM integrations WHERE provider_name IN (#{RETIRED.map { |n| "'#{n}'" }.join(', ')})")
  end

  # Irreversible on purpose: restoring a row would restore a credential this
  # migration deliberately dropped, and nothing would consume it.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
