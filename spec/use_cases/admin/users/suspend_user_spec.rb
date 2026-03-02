require "rails_helper"

RSpec.describe Admin::Users::SuspendUser do
  let(:admin) { create(:user, role: :admin) }
  let(:regular_user) { create(:user) }

  describe "#call" do
    it "suspends a regular user" do
      result = described_class.call(user_id: regular_user.id, admin: admin)
      expect(result).to be_success
      expect(regular_user.reload.status).to eq("suspended")
    end

    it "returns failure when user not found" do
      result = described_class.call(user_id: 999, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it "returns failure when trying to suspend an admin" do
      another_admin = create(:user, role: :admin)
      result = described_class.call(user_id: another_admin.id, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
    end

    it "returns failure when user already suspended" do
      regular_user.update!(status: :suspended)
      result = described_class.call(user_id: regular_user.id, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:already_suspended)
    end

    it "publishes Identity::UserSuspended event" do
      handler = double("handler")
      allow(handler).to receive(:call)
      EventBus.subscribe(Identity::UserSuspended, handler)

      described_class.call(user_id: regular_user.id, admin: admin)
      expect(handler).to have_received(:call).with(an_instance_of(Identity::UserSuspended))
    end
  end
end
