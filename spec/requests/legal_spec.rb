require "rails_helper"

RSpec.describe "Legal pages", type: :request do
  describe "GET /privacy" do
    before { get privacy_path }

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "references NLFPDPPP (the DOF 20-mar-2025 framework)" do
      expect(response.body).to match(/NLFPDPPP/i)
      expect(response.body).to include("20 de marzo de 2025")
    end

    it "no longer claims that no data is transferred to third parties" do
      expect(response.body).not_to match(/no transferimos.*terceros/i)
    end

    it "discloses remisiones (hosting + email providers) per Arts. 35-36" do
      expect(response.body).to include("Arts. 35 y 36")
      expect(response.body).to match(/hosting/i)
      expect(response.body).to match(/envío de correo/i)
    end

    it "distinguishes finalidades necesarias and voluntarias (Art. 15)" do
      expect(response.body).to include("Art. 15")
      expect(response.body).to include("Finalidades necesarias")
      expect(response.body).to include("Finalidades voluntarias")
    end

    it "declares a retention policy" do
      expect(response.body).to match(/conservamos/i)
      expect(response.body).to include("30 días")
    end

    it "states the ARCO response window is 20 días hábiles (Art. 32)" do
      expect(response.body).to include("20 días hábiles")
      expect(response.body).to include("Art. 32")
    end

    it "covers revocación del consentimiento as an additional right" do
      expect(response.body).to match(/revocación del consentimiento/i)
    end

    it "if INAI is mentioned, it is in the historical/extinguished context (not as active authority)" do
      if response.body.include?("INAI")
        expect(response.body).to match(/INAI.{0,200}extingui/m)
      end
    end

    it "mentions the new authority context (SABG or autoridad competente)" do
      expect(response.body).to match(/SABG|Secretaría Anticorrupción|autoridad mexicana competente/)
    end

    it "calls out Art. 8 patrimonial data express consent" do
      expect(response.body).to include("Art. 8")
      expect(response.body).to match(/patrimoniales/i)
    end

    it "references the operational ARCO procedure doc" do
      expect(response.body).to include("docs/ops/arco-procedure.md")
    end
  end

  describe "ARCO procedure ops doc" do
    it "exists at docs/ops/arco-procedure.md" do
      path = Rails.root.join("docs/ops/arco-procedure.md")
      expect(File.exist?(path)).to be true
    end

    it "documents the 20 días hábiles deadline" do
      content = File.read(Rails.root.join("docs/ops/arco-procedure.md"))
      expect(content).to include("20 días hábiles")
      expect(content).to include("Art. 32")
    end

    it "documents identity validation steps" do
      content = File.read(Rails.root.join("docs/ops/arco-procedure.md"))
      expect(content).to match(/validación de identidad/i)
    end
  end
end
