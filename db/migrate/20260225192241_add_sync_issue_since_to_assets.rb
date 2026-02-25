class AddSyncIssueSinceToAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :sync_issue_since, :datetime
  end
end
