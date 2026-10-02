require "rails_helper"

RSpec.describe Identity::UseCases::UpdateInfo do
  let(:user) { create(:user, full_name: "Alex Trader", email: "alex@example.com") }

  describe ".call" do
    it "updates user info and returns Success" do
      result = described_class.call(user: user, params: { full_name: "Alex Updated", email: "newemail@example.com" },
                                    current_password: "password123")

      expect(result).to be_success
      user.reload
      expect(user.full_name).to eq("Alex Updated")
      expect(user.email).to eq("newemail@example.com")
    end

    it "publishes ProfileUpdated event" do
      received = []
      EventBus.subscribe(Identity::Events::ProfileUpdated, ->(e) { received << e })

      described_class.call(user: user, params: { full_name: "Alex Updated", email: "newemail@example.com" },
                           current_password: "password123")

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

    it "keeps the email and returns :unauthorized when the current password is wrong" do
      result = described_class.call(user: user, params: { full_name: "Alex", email: "new@example.com" },
                                    current_password: "wrong-password")

      expect(result.failure[0]).to eq(:unauthorized)
      expect(user.reload.email).to eq("alex@example.com")
    end

    it "keeps the email and returns :unauthorized when no password is given" do
      [ nil, "" ].each do |blank|
        result = described_class.call(user: user, params: { full_name: "Alex", email: "new@example.com" },
                                      current_password: blank)

        expect(result.failure[0]).to eq(:unauthorized)
      end
      expect(user.reload.email).to eq("alex@example.com")
    end

    it "changes only the name without a password when the email is the same" do
      result = described_class.call(user: user, params: { full_name: "Alex Renamed", email: "Alex@Example.com" })

      expect(result).to be_success
      expect(user.reload.full_name).to eq("Alex Renamed")
      expect(user.email).to eq("alex@example.com")
    end

    it "returns Failure when email is already taken by another user" do
      create(:user, email: "taken@example.com")
      result = described_class.call(user: user, params: { full_name: "Alex", email: "taken@example.com" },
                                    current_password: "password123")

      expect(result).to be_failure
      expect(result.failure[1][:email]).to be_present
    end
  end
end
