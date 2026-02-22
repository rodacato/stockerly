class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user,              null: false, foreign_key: true, index: false
      t.string     :title,             null: false
      t.text       :body
      t.integer    :notification_type, null: false, default: 0
      t.boolean    :read,              null: false, default: false
      t.references :notifiable,        polymorphic: true, index: true

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, [:user_id, :created_at]
  end
end
