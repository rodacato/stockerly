require "rails_helper"

RSpec.describe Identity::UseCases::ResetPassword do
  describe ".call" do
    let(:user) { create(:user, password: "oldpassword123", password_confirmation: "oldpassword123") }
    let(:token) { user.password_reset_token }

    it "resets password and returns Success" do
      result = described_class.call(
        token: token,
        params: { password: "newpassword123", password_confirmation: "newpassword123" }
      )

      expect(result).to be_success
      expect(user.reload.authenticate("newpassword123")).to be_truthy
    end

    it "destroys all remember tokens" do
      create(:remember_token, user: user)
      create(:remember_token, user: user)

      expect {
        described_class.call(
          token: token,
          params: { password: "newpassword123", password_confirmation: "newpassword123" }
        )
      }.to change { user.remember_tokens.count }.from(2).to(0)
    end

    it "returns Failure for invalid token" do
      result = described_class.call(
        token: "invalid-token",
        params: { password: "newpassword123", password_confirmation: "newpassword123" }
      )

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:invalid_token)
    end

    it "returns Failure for short password" do
      result = described_class.call(
        token: token,
        params: { password: "short", password_confirmation: "short" }
      )

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for mismatched confirmation" do
      result = described_class.call(
        token: token,
        params: { password: "newpassword123", password_confirmation: "different123" }
      )

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      # Use case now returns the user object (with errors attached) so the
      # controller can re-render the form with feedback. Field-level
      # assertions go through ActiveModel::Errors instead of a Hash.
      expect(result.failure[1]).to be_a(User)
      expect(result.failure[1].errors[:password_confirmation]).to be_present
    end
  end
end
