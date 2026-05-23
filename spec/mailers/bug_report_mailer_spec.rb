require "rails_helper"

RSpec.describe BugReportMailer, type: :mailer do
  describe "#notify" do
    let(:user) { create(:user, full_name: "Pablo Reyes", email: "pablo@example.com") }
    let(:mail) { described_class.notify(user: user, title: "La gráfica no carga", description: "Detalles del problema aquí.") }

    it "delivers to the support inbox" do
      expect(mail.to).to eq([ "support@notdefined.dev" ])
    end

    it "sets reply-to to the user's email" do
      expect(mail.reply_to).to eq([ "pablo@example.com" ])
    end

    it "includes the title in the subject" do
      expect(mail.subject).to include("La gráfica no carga")
      expect(mail.subject).to start_with("[Bug beta]")
    end

    it "renders the canonical Stockerly logo via the mailer layout" do
      # Propshaft fingerprints the URL as logo_light-<digest>.svg, so we match
      # the stable stem rather than the literal filename.
      expect(mail.html_part.decoded).to match(%r{logo_light-[0-9a-f]+\.svg})
      expect(mail.html_part.decoded).to include('alt="Stockerly"')
    end

    it "includes user identity and reported text in both body parts" do
      [ mail.text_part.decoded, mail.html_part.decoded ].each do |body|
        expect(body).to include("Pablo Reyes")
        expect(body).to include("pablo@example.com")
        expect(body).to include("La gráfica no carga")
        expect(body).to include("Detalles del problema aquí.")
      end
    end
  end
end
