class DropBrowserPushFromAlertPreferences < ActiveRecord::Migration[8.1]
  # D16 closed: the in-app bell is not a channel you can switch off, and no
  # push channel was ever built — no gem, no VAPID pair, no subscriptions
  # table, and the service worker's `push` listener is still the commented
  # scaffold Rails generates. §7 kept the column pending exactly this call.
  #
  # Reversible on purpose: if push is revived it comes back with the same
  # default, and the data it would have held never existed.
  def change
    remove_column :alert_preferences, :browser_push, :boolean, null: false, default: true
  end
end
