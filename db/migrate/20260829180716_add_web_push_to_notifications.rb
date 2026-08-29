class AddWebPushToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :alert_preferences, :push, :boolean, default: false, null: false

    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      # The browser's own URL for this install, and the keys it hands out to
      # encrypt payloads to it. Rotating either means a new subscription.
      t.string :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false
      t.datetime :last_delivered_at

      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end
