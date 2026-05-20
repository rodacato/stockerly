class AddReadAtToNotifications < ActiveRecord::Migration[8.1]
  def up
    add_column :notifications, :read_at, :datetime
    Notification.where(read: true).where(read_at: nil).find_each do |n|
      n.update_column(:read_at, n.updated_at)
    end
  end

  def down
    remove_column :notifications, :read_at
  end
end
