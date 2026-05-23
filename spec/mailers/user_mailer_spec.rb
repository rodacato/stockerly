require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, email: "test@example.com", full_name: "Jane Doe") }

  shared_examples "logo-bearing mailer" do
    it "renders the canonical Stockerly logo via the mailer layout (absolute URL)" do
      # Propshaft fingerprints the URL as logo_light-<digest>.svg, so we match
      # the stable stem rather than the literal filename.
      expect(mail.body.encoded).to match(%r{logo_light-[0-9a-f]+\.svg})
      expect(mail.body.encoded).to include('alt="Stockerly"')
    end

    it "sends to the user's email" do
      expect(mail.to).to eq([ "test@example.com" ])
    end
  end

  describe "#welcome" do
    let(:mail) { described_class.welcome(user) }

    it_behaves_like "logo-bearing mailer"

    it "uses the es-MX subject" do
      expect(mail.subject).to eq("Bienvenido a Stockerly")
    end

    it "addresses the user in es-MX body" do
      expect(mail.body.encoded).to include("Bienvenido a Stockerly, Jane Doe")
    end
  end

  describe "#password_reset" do
    let(:reset_url) { "https://stockerly.com/reset-password/abc123" }
    let(:mail) { described_class.password_reset(user, reset_url) }

    it_behaves_like "logo-bearing mailer"

    it "uses the es-MX subject" do
      expect(mail.subject).to eq("Restablece tu contraseña de Stockerly")
    end

    it "includes the reset link" do
      expect(mail.body.encoded).to include(reset_url)
      expect(mail.body.encoded).to include("Restablecer mi contraseña")
    end
  end

  describe "#verify_email" do
    let(:url) { "https://stockerly.com/verify-email/xyz" }
    let(:mail) { described_class.verify_email(user, url) }

    it_behaves_like "logo-bearing mailer"

    it "uses the es-MX subject" do
      expect(mail.subject).to eq("Verifica tu correo de Stockerly")
    end

    it "embeds the verification link" do
      expect(mail.body.encoded).to include(url)
      expect(mail.body.encoded).to include("Verificar mi correo")
    end
  end

  describe "#account_suspended" do
    let(:mail) { described_class.account_suspended(user) }

    it_behaves_like "logo-bearing mailer"

    it "uses the es-MX subject" do
      expect(mail.subject).to eq("Tu cuenta de Stockerly fue suspendida")
    end
  end

  describe "#account_reactivated" do
    let(:mail) { described_class.account_reactivated(user) }

    it_behaves_like "logo-bearing mailer"

    it "uses the es-MX subject" do
      expect(mail.subject).to eq("Tu cuenta de Stockerly fue reactivada")
    end
  end
end
