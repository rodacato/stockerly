class RemoveAlphaVantageIntegration < ActiveRecord::Migration[8.1]
  # Its gateway, registration and directory entry are gone (D123), and Yahoo
  # serves the overview and statements it did. Same reasoning as
  # RemoveRetiredIntegrations: a row without a gateway is a key nobody spends,
  # on a screen that reads it as a source that could be reconnected.
  def up
    execute("DELETE FROM integrations WHERE provider_name = 'Alpha Vantage'")
  end

  # Restoring the row would restore a credential this deliberately dropped.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
