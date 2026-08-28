require "rails_helper"

RSpec.describe Identity::Domain::Totp do
  let(:secret) { "JBSWY3DPEHPK3PXP" }

  describe ".verify" do
    it "accepts the code the authenticator is showing" do
      expect(described_class.verify(secret: secret, code: ROTP::TOTP.new(secret).now)).to be_present
    end

    it "refuses a wrong code, a blank one, and a blank secret" do
      expect(described_class.verify(secret: secret, code: "000000")).to be_nil
      expect(described_class.verify(secret: secret, code: "")).to be_nil
      expect(described_class.verify(secret: "", code: "123456")).to be_nil
    end

    it "tolerates the spaces some apps put in the middle" do
      code = ROTP::TOTP.new(secret).now
      spaced = "#{code[0..2]} #{code[3..]}"

      expect(described_class.verify(secret: secret, code: spaced)).to be_present
    end

    # The replay guard: `after` is the timestamp of a code already spent.
    it "refuses a code from a window that was already used" do
      code = ROTP::TOTP.new(secret).now
      used_at = described_class.verify(secret: secret, code: code)

      expect(described_class.verify(secret: secret, code: code, after: Time.at(used_at))).to be_nil
    end
  end

  describe ".provisioning_uri" do
    it "carries the issuer and the account, so the app names it" do
      uri = described_class.provisioning_uri(secret: secret, email: "adrian@example.com")

      expect(uri).to start_with("otpauth://totp/")
      expect(uri).to include("Stockerly")
      expect(uri).to include("adrian%40example.com")
    end
  end

  describe ".format_for_display" do
    it "groups the secret so it can be typed by hand" do
      expect(described_class.format_for_display(secret)).to eq("JBSW Y3DP EHPK 3PXP")
    end
  end
end
