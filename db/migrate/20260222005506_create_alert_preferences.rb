class CreateAlertPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_preferences do |t|
      t.references :user,              null: false, foreign_key: true, index: { unique: true }
      t.boolean    :browser_push,      null: false, default: true
      t.boolean    :email_digest,      null: false, default: true
      t.boolean    :sms_notifications, null: false, default: false

      t.timestamps
    end
  end
end
