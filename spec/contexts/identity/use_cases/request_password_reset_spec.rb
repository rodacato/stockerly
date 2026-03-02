require "rails_helper"

RSpec.describe Identity::RequestPasswordReset do
  describe ".call" do
    it "returns Success and logs URL for existing user" do
      user = create(:user, email: "alex@example.com")

      expect(Rails.logger).to receive(:info).with(/PASSWORD RESET.*alex@example.com/)

      result = described_class.call(params: { email: "alex@example.com" })

      expect(result).to be_success
      expect(result.value!).to eq(:sent)
    end

    it "returns Success for non-existing email (anti-enumeration)" do
      result = described_class.call(params: { email: "nobody@example.com" })

      expect(result).to be_success
      expect(result.value!).to eq(:sent)
    end

    it "returns Failure for empty email" do
      result = described_class.call(params: { email: "" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
