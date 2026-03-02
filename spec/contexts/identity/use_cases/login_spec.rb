require "rails_helper"

RSpec.describe Identity::Login do
  describe ".call" do
    let(:user) { create(:user, email: "alex@example.com", password: "password123") }

    it "returns Success with valid credentials" do
      result = described_class.call(params: { email: user.email, password: "password123" })

      expect(result).to be_success
      expect(result.value!).to eq(user)
    end

    it "handles case-insensitive email" do
      result = described_class.call(params: { email: " #{user.email.upcase} ", password: "password123" })

      expect(result).to be_success
      expect(result.value!).to eq(user)
    end

    it "returns Failure for wrong password" do
      result = described_class.call(params: { email: user.email, password: "wrong" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:invalid_credentials)
    end

    it "returns Failure for non-existent email" do
      result = described_class.call(params: { email: "nobody@example.com", password: "password123" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:invalid_credentials)
    end

    it "returns Failure for suspended user" do
      user.update!(status: :suspended)

      result = described_class.call(params: { email: user.email, password: "password123" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:suspended)
      expect(result.failure[1]).to include("suspended")
    end

    it "returns Failure for empty email" do
      result = described_class.call(params: { email: "", password: "password123" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
