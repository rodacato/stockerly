class LabelTheIpcByItsProxy < ActiveRecord::Migration[8.1]
  # The IPC's own DataBursatil feed is frozen at 2026-06-26, so the day's move
  # now comes from NAFTRAC, the ETF that tracks it. The name is what the asset
  # detail renders, so it is where that has to be said — showing a proxy under
  # the index's own name would be the app claiming a figure it does not have.
  #
  # The stored level goes with it: an ETF price in pesos is not an index level,
  # and nothing renders `value` anyway.
  def up
    execute <<~SQL.squish
      UPDATE market_indices
         SET name = 'NAFTRAC · sigue al IPC', value = NULL, updated_at = NOW()
       WHERE symbol = 'IPC'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE market_indices
         SET name = 'IPC Mexico', updated_at = NOW()
       WHERE symbol = 'IPC'
    SQL
  end
end
