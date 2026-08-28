class RemoveMultiUserColumnsFromUsers < ActiveRecord::Migration[8.1]
  # ADR-0010 turned Stockerly into a self-hosted single-user tracker: registration
  # and email verification were deleted, and moderation never existed — nothing
  # ever set `status` to suspended or wrote either verification column. The
  # columns outlived the surface that gave them meaning (#381).
  def change
    remove_index :users, :status, name: "index_users_on_status"
    remove_column :users, :status, :integer, default: 0, null: false
    remove_column :users, :email_verified_at, :datetime
    remove_column :users, :is_verified, :boolean, default: false, null: false
  end
end
