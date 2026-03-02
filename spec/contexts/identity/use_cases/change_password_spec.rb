require "rails_helper"

RSpec.describe Identity::UseCases::ChangePassword do
  let(:user) { create(:user, password: "OldPassword123", password_confirmation: "OldPassword123") }

  describe ".call" do
    let(:valid_params) do
      { current_password: "OldPassword123", password: "NewPassword456", password_confirmation: "NewPassword456" }
    end

    it "changes password and returns Success" do
      result = described_class.call(user: user, params: valid_params)

      expect(result).to be_success
      expect(user.reload.authenticate("NewPassword456")).to be_truthy
    end

    it "publishes PasswordChanged event" do
      received = []
      EventBus.subscribe(Identity::Events::PasswordChanged, ->(e) { received << e })

      described_class.call(user: user, params: valid_params)

      expect(received.size).to eq(1)
      expect(received.first.user_id).to eq(user.id)
    end

    it "returns Failure when current password is wrong" do
      params = valid_params.merge(current_password: "WrongPassword")
      result = described_class.call(user: user, params: params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:unauthorized)
    end

    it "returns Failure when new password is too short" do
      params = valid_params.merge(password: "short", password_confirmation: "short")
      result = described_class.call(user: user, params: params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure when confirmation does not match" do
      params = valid_params.merge(password_confirmation: "DifferentPassword")
      result = described_class.call(user: user, params: params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
