class RenameSmsNotificationsToUrgentEmail < ActiveRecord::Migration[8.1]
  # The column never carried SMS: nothing in the app has ever sent one, and the
  # alerts screen already labelled the same boolean "Avisos urgentes por correo"
  # while /profile promised SMS via Twilio. Rename it to what the one working
  # consumer means.
  def change
    rename_column :alert_preferences, :sms_notifications, :urgent_email
  end
end
