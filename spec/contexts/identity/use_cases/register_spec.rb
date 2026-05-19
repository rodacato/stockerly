require "rails_helper"

RSpec.describe Identity::UseCases::Register do
  describe ".call" do
    let(:invite) { create(:invite_code) }

    let(:valid_params) do
      {
        full_name: "John Doe",
        email: "john@example.com",
        password: "password123",
        password_confirmation: "password123",
        invite_code: invite.code,
        consents_data_processing: true
      }
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

    it "persists the Art. 8 LFPDPPP consent timestamp" do
      result = described_class.call(params: valid_params)

      expect(result).to be_success
      user = result.value!
      expect(user.consents_data_processing_at).to be_present
      expect(user.consents_data_processing_at).to be_within(1.minute).of(Time.current)
    end

    it "returns Failure when Art. 8 consent is not granted" do
      result = described_class.call(params: valid_params.merge(consents_data_processing: false))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1]).to have_key(:consents_data_processing)
    end

    it "consumes the invite code atomically with user creation" do
      result = described_class.call(params: valid_params)

      expect(result).to be_success
      invite.reload
      expect(invite.used_at).to be_present
      expect(invite.used_by_user).to eq(result.value!)
    end

    it "accepts hyphenated invite_code by normalizing" do
      hyphenated = invite.formatted_code
      result = described_class.call(params: valid_params.merge(invite_code: hyphenated))

      expect(result).to be_success
      invite.reload
      expect(invite).to be_used
    end

    it "publishes UserRegistered event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(Identity::Events::UserRegistered))

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

    it "returns Failure for missing invite_code" do
      result = described_class.call(params: valid_params.except(:invite_code))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1]).to have_key(:invite_code)
    end

    it "returns Failure for nonexistent invite_code" do
      result = described_class.call(params: valid_params.merge(invite_code: "deadbeef1234"))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1][:invite_code]).to include(match(/inválido/))
    end

    it "returns Failure for already-used invite_code" do
      used_invite = create(:invite_code, :used)
      result = described_class.call(params: valid_params.merge(invite_code: used_invite.code))

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1][:invite_code]).to include(match(/canjeado/))
    end

    it "returns Failure for duplicate email and does not consume the invite" do
      create(:user, email: "john@example.com")

      result = described_class.call(params: valid_params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1]).to have_key(:email)

      invite.reload
      expect(invite).not_to be_used
    end
  end
end
