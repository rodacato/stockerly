require "rails_helper"

# Profile revamp (S09 #97) — asserts es-MX surface, tabbed settings, the ARCO
# data-export link, and the explicit removal of the watchlist embed (which now
# lives only on /dashboard and /market). Preferences moved to /settings.
RSpec.describe "Profile revamp (S09 #97)", type: :request do
  let(:user) { create(:user, email: "p97@example.com", full_name: "Adrian Castillo", preferred_currency: "MXN", password: "password123") }

  before { login_as(user) }

  describe "GET /profile" do
    before { get profile_path }

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the es-MX header (kicker, name, member-since line)" do
      expect(response.body).to include("Tu perfil")
      expect(response.body).to include("Adrian Castillo")
      expect(response.body).to include("Miembro desde")
    end

    it "renders the three tabbed settings" do
      # Tab labels live in <button> nodes; match label text rather than
      # exact node delimiters since the buttons carry many class names.
      expect(response.body).to include("Información")
      expect(response.body).to include("Seguridad")
      expect(response.body).to include("Datos y sesión")
    end

    it "renders the Información tab content (form labels in es-MX)" do
      expect(response.body).to include("Información personal")
      expect(response.body).to include("Nombre completo")
      expect(response.body).to include("Correo electrónico")
      expect(response.body).to include("Guardar cambios")
    end

    it "renders the Seguridad tab (password fields es-MX)" do
      expect(response.body).to include("Contraseña actual")
      expect(response.body).to include("Nueva contraseña")
      expect(response.body).to include("Confirmar nueva contraseña")
      expect(response.body).to include("Cambiar contraseña")
    end

    # Theme, currency and the two email switches live on /settings, which owns
    # them without a Guardar to forget. Keeping a second copy here is what this
    # assertion exists to prevent.
    it "does not repeat the preferences /settings owns" do
      expect(response.body).not_to include("Preferencias")
      expect(response.body).not_to include("Moneda preferida")
      expect(response.body).not_to include("data-toggle-field-value")
      expect(response.body).not_to include('data-controller="theme"')
    end

    it "renders the Datos y sesión tab with ARCO export + delete-account links + sign-out" do
      expect(response.body).to include("Tus datos")
      expect(response.body).to include("derechos ARCO")
      expect(response.body).to include("Solicitar acceso a mis datos")
      expect(response.body).to include("Eliminar mi cuenta")
      expect(response.body).to include("Cerrar sesión")
      expect(response.body).to include(Stockerly::SUPPORT_EMAIL)
    end

    it "does NOT embed the watchlist (lives in /dashboard + /market per S09 #97)" do
      # Old layout rendered "My Watchlist" + the table here; should be gone.
      expect(response.body).not_to include("My Watchlist")
    end

    it "does NOT contain the previous English copy" do
      expect(response.body).not_to include("Personal Information")
      expect(response.body).not_to include("Account Settings")
      expect(response.body).not_to include("Edit Settings")
      expect(response.body).not_to include("Member since")
    end
  end

  describe "PATCH /profile updates preferred_currency" do
    it "persists the new currency and redirects with es-MX notice" do
      patch profile_path, params: { profile: { full_name: user.full_name, email: user.email, preferred_currency: "USD" } }

      expect(response).to redirect_to(profile_path)
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
