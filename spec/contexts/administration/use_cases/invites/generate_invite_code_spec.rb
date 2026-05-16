require "rails_helper"

RSpec.describe Administration::UseCases::Invites::GenerateInviteCode do
  let(:admin) { create(:user, :admin) }

  describe "#call" do
    it "creates an unused invite code" do
      result = described_class.call(admin: admin)

      expect(result).to be_success
      invite = result.value!
      expect(invite).to be_persisted
      expect(invite.code).to match(/\A[a-f0-9]{12}\z/)
      expect(invite).not_to be_used
      expect(invite.created_by_user).to eq(admin)
    end

    it "stores an optional note" do
      result = described_class.call(admin: admin, note: "Pablo")
      expect(result.value!.note).to eq("Pablo")
    end

    it "ignores blank notes" do
      result = described_class.call(admin: admin, note: "")
      expect(result.value!.note).to be_nil
    end

    it "rejects non-admin callers" do
      non_admin = create(:user)
      result = described_class.call(admin: non_admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
    end

    it "rejects nil admin" do
      result = described_class.call(admin: nil)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
    end

    it "generates unique codes across calls" do
      first  = described_class.call(admin: admin).value!
      second = described_class.call(admin: admin).value!
      expect(first.code).not_to eq(second.code)
    end
  end
end
