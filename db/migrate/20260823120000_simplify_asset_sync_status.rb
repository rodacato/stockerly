class SimplifyAssetSyncStatus < ActiveRecord::Migration[8.1]
  def up
    # Status is now binary/user-controlled: collapse auto-managed sync_issue(2)
    # rows back to active(0). Failures now live in last_sync_error, not status.
    execute "UPDATE assets SET sync_status = 0 WHERE sync_status = 2"

    add_column :assets, :last_synced_at, :datetime
    add_column :assets, :last_sync_error, :text

    # Seed from the last successful price so rows don't read "sin sincronizar".
    execute "UPDATE assets SET last_synced_at = price_updated_at WHERE price_updated_at IS NOT NULL"

    remove_column :assets, :sync_issue_since, :datetime
  end

  def down
    add_column :assets, :sync_issue_since, :datetime
    remove_column :assets, :last_sync_error
    remove_column :assets, :last_synced_at
  end
end
