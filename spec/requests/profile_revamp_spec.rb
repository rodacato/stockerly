require "rails_helper"

# Profile revamp (S09 #97) — asserts es-MX surface, tabbed settings, the ARCO
# data-export link, and the explicit removal of the watchlist embed (which now
# lives only on /dashboard and /market). Preferences moved to /settings.
RSpec.describe "Profile revamp (S09 #97)", type: :request do
  let(:user) { create(:user, email: "p97@example.com", full_name: "Adrian Castillo", preferred_currency: "MXN", password: "password123") }

  before { login_as(user) }

  # /profile is retired (D5, finally executed). Its two real forms are their own
  # screens now; everything else it held either duplicated the Ajustes hub or
  # contradicted it — the Datos y sesión tab told the owner to email support to
  # delete an account the hub already deletes in-app.
  describe "the screens that replaced it" do
    # Asked of the route set rather than of a response, so the assertion does
    # not depend on how this environment renders an unmatched route.
    it "no longer routes GET /profile, while the form it submits to stays" do
      expect { Rails.application.routes.recognize_path("/profile", method: :get) }
        .to raise_error(ActionController::RoutingError)
      expect(Rails.application.routes.recognize_path("/profile", method: :patch))
        .to include(controller: "profiles", action: "update")
    end

    it "puts name and email on their own screen, with a way back to the hub" do
      get edit_account_settings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Adrian Castillo", I18n.t("settings.account.nombre"), I18n.t("settings.account.correo"))
      expect(response.body).to include(settings_path)
    end

    it "puts the password change on its own screen" do
      get edit_password_settings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("settings.password.current_password"),
        I18n.t("settings.password.password"),
        I18n.t("settings.password.password_confirmation")
      )
    end

    # Negative: the hub owns theme, currency and the two email switches, and a
    # second copy is what this assertion exists to prevent.
    it "does not repeat the preferences the hub owns" do
      get edit_account_settings_path

      expect(response.body).not_to include(I18n.t("settings.show.avisos_titulo"))
      expect(response.body).not_to include(I18n.t("settings.show.moneda"))
    end

    # The defect that retiring it fixed: two contradictory answers to "how do I
    # delete my account", in the same app.
    it "leaves one answer for deleting the account, and it is the hub's" do
      get edit_account_settings_path
      expect(response.body).not_to include("ARCO")

      get settings_path
      expect(response.body).to include(I18n.t("settings.show.borrar_cuenta_cta"))
    end
  end

  describe "PATCH /profile updates preferred_currency" do
    it "persists the new currency and redirects with es-MX notice" do
      patch profile_path, params: { profile: { full_name: user.full_name, email: user.email, preferred_currency: "USD" } }

      expect(response).to redirect_to(edit_account_settings_path)
      follow_redirect!
      expect(response.body).to include("Perfil actualizado")
      expect(user.reload.preferred_currency).to eq("USD")
    end

    it "leaves preferred_currency untouched when the param is absent" do
      patch profile_path, params: { profile: { full_name: "New Name", email: user.email } }
      expect(user.reload.preferred_currency).to eq("MXN")
      expect(user.reload.full_name).to eq("New Name")
    end

    # D58: the Ajustes pill is the only caller of /profile/currency now that the
    # profile form is gone, and it PATCHes on select with no page to land on,
    # so the endpoint answers a status.
    it "answers a status when the Ajustes pill writes the currency" do
      patch update_currency_path, params: { profile: { preferred_currency: "USD" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.preferred_currency).to eq("USD")
    end

    it "refuses an unsupported currency over JSON without writing it" do
      patch update_currency_path, params: { profile: { preferred_currency: "EUR" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.preferred_currency).to eq("MXN")
    end
  end
end
