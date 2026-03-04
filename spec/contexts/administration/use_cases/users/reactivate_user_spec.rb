require "rails_helper"

RSpec.describe Administration::UseCases::Users::ReactivateUser do
  let(:admin) { create(:user, role: :admin) }
  let(:suspended_user) { create(:user, status: :suspended) }

  describe "#call" do
    it "reactivates a suspended user" do
      result = described_class.call(user_id: suspended_user.id, admin: admin)
      expect(result).to be_success
      expect(suspended_user.reload.status).to eq("active")
    end

    it "returns failure when user not found" do
      result = described_class.call(user_id: 999, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it "returns failure when trying to reactivate an admin" do
      another_admin = create(:user, role: :admin, status: :suspended)
      result = described_class.call(user_id: another_admin.id, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
    end

    it "returns failure when user is not suspended" do
      active_user = create(:user)
      result = described_class.call(user_id: active_user.id, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_suspended)
    end

    it "publishes Identity::Events::UserReactivated event" do
      handler = double("handler")
      allow(handler).to receive(:call)
      EventBus.subscribe(Identity::Events::UserReactivated, handler)

      described_class.call(user_id: suspended_user.id, admin: admin)
      expect(handler).to have_received(:call).with(an_instance_of(Identity::Events::UserReactivated))
    end
  end
end
