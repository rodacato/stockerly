require "rails_helper"

RSpec.describe Identity::Register do
  describe ".call" do
    let(:valid_params) do
      { full_name: "John Doe", email: "john@example.com", password: "password123", password_confirmation: "password123" }
    end

    it "creates a user and returns Success" do
      result = described_class.call(params: valid_params)

      expect(result).to be_success
      user = result.value!
      expect(user).to be_a(User)
      expect(user).to be_persisted
      expect(user.full_name).to eq("John Doe")
      expect(user.email).to eq("john@example.com")
    end

    it "publishes UserRegistered event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(UserRegistered))

      described_class.call(params: valid_params)
    end

    it "returns Failure for missing full_name" do
      result = described_class.call(params: valid_params.merge(full_name: ""))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for invalid email" do
      result = described_class.call(params: valid_params.merge(email: "not-an-email"))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for short password" do
      result = described_class.call(params: valid_params.merge(password: "short", password_confirmation: "short"))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for mismatched password confirmation" do
      result = described_class.call(params: valid_params.merge(password_confirmation: "different123"))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1]).to have_key(:password_confirmation)
    end

    it "returns Failure for duplicate email" do
      create(:user, email: "john@example.com")

      result = described_class.call(params: valid_params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1]).to have_key(:email)
    end
  end
end
