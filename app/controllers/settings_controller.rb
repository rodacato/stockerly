class SettingsController < AuthenticatedController
  # The Ajustes hub (D5): on a single-user instance the admin split was a
  # costume. One screen with sections, linking to the surfaces that already
  # exist rather than reimplementing them.
  def show
    @user = current_user
    @preferences = current_user.alert_preference
    @integrations_count = Integration.count
  end
end
