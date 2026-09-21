require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123", onboarded_at: Time.current) }

  describe "GET /login" do
    it "renders the login page" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Inicia sesión")
      expect(response.body).to include("Correo electrónico")
    end

    it "redirects to dashboard if already logged in" do
      post login_path, params: { email: user.email, password: "password123" }
      get login_path
      expect(response).to redirect_to(dashboard_path)
    end

    it "leaves the guard's nudge as a toast rather than an error in the card" do
      get dashboard_path
      follow_redirect!

      expect(response.body).to include(I18n.t("auth.flash.requiere_sesion"))
      expect(Capybara.string(response.body)).to have_no_css("main [role='alert']")
    end

    context "when the nudge is reworded" do
      around do |example|
        I18n.backend.store_translations(:"es-MX", auth: { flash: { requiere_sesion: "Necesitas una sesión." } })
        example.run
        I18n.backend.reload!
      end

      it "still keeps it out of the card, because the filter reads the locale" do
        get dashboard_path
        follow_redirect!

        expect(response.body).to include("Necesitas una sesión.")
        expect(Capybara.string(response.body)).to have_no_css("main [role='alert']")
      end
    end
  end

  describe "POST /login" do
    it "logs in with valid credentials" do
      post login_path, params: { email: "test@example.com", password: "password123" }
      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to match(/Qué gusto verte de vuelta/)
    end

    it "rejects invalid password" do
      post login_path, params: { email: "test@example.com", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to match(/Correo o contraseña/)
    end

    it "states a failed login once, inside the card, not again as a toast" do
      post login_path, params: { email: user.email, password: "wrongpassword" }

      expect(response.body.scan("Correo o contraseña inválidos.").size).to eq(1)
      expect(Capybara.string(response.body)).to have_css("main [role='alert']", text: "Correo o contraseña inválidos.")
    end

    it "rejects unknown email" do
      post login_path, params: { email: "nobody@example.com", password: "password123" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Correo o contraseña inválidos")
    end

    it "handles case-insensitive email" do
      post login_path, params: { email: "TEST@EXAMPLE.COM", password: "password123" }
      expect(response).to redirect_to(dashboard_path)
    end

    it "rejects login with missing email param" do
      post login_path, params: { password: "password123" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Correo o contraseña inválidos")
    end
  end

  describe "DELETE /logout" do
    before do
      login_as(user)
    end

    it "logs out and redirects to root" do
      delete logout_path
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Sesión cerrada correctamente.")
    end
  end

  describe "DELETE /logout without session" do
    it "handles logout when not logged in" do
      delete logout_path
      expect(response).to redirect_to(root_path)
    end
  end
end
