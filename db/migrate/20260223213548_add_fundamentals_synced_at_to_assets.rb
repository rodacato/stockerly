class AddFundamentalsSyncedAtToAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :fundamentals_synced_at, :datetime
  end
end
