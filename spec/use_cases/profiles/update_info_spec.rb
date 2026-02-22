require "rails_helper"

RSpec.describe Profiles::UpdateInfo do
  let(:user) { create(:user, full_name: "Alex Trader", email: "alex@example.com") }

  describe ".call" do
    it "updates user info and returns Success" do
      result = described_class.call(user: user, params: { full_name: "Alex Updated", email: "newemail@example.com" })

      expect(result).to be_success
      user.reload
      expect(user.full_name).to eq("Alex Updated")
      expect(user.email).to eq("newemail@example.com")
    end

    it "publishes ProfileUpdated event" do
      received = []
      EventBus.subscribe(ProfileUpdated, ->(e) { received << e })

      described_class.call(user: user, params: { full_name: "Alex Updated", email: "newemail@example.com" })

      expect(received.size).to eq(1)
      expect(received.first.user_id).to eq(user.id)
    end

    it "returns Failure when full_name is too short" do
      result = described_class.call(user: user, params: { full_name: "A", email: "alex@example.com" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure when email format is invalid" do
      result = described_class.call(user: user, params: { full_name: "Alex", email: "not-an-email" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure when email is already taken by another user" do
      create(:user, email: "taken@example.com")
      result = described_class.call(user: user, params: { full_name: "Alex", email: "taken@example.com" })

      expect(result).to be_failure
      expect(result.failure[1][:email]).to be_present
    end
  end
end
