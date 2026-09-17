class RemoveFmpIntegration < ActiveRecord::Migration[8.1]
  # FMP only backed Alpha Vantage up, with a key that works for accounts
  # created before 2025-08-31. Its gateway and registration are gone (D123).
  def up
    execute("DELETE FROM integrations WHERE provider_name = 'FMP'")
  end

  # Restoring the row would restore a credential this deliberately dropped.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
