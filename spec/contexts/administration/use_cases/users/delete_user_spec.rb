require "rails_helper"

RSpec.describe Administration::UseCases::Users::DeleteUser do
  let(:admin) { create(:user, role: :admin) }
  let(:regular_user) { create(:user) }

  describe "#call" do
    it "deletes a regular user" do
      result = described_class.call(user_id: regular_user.id, admin: admin)
      expect(result).to be_success
      expect(result.value![:email]).to eq(regular_user.email)
      expect(User.find_by(id: regular_user.id)).to be_nil
    end

    it "deletes a suspended user" do
      regular_user.update!(status: :suspended)
      result = described_class.call(user_id: regular_user.id, admin: admin)
      expect(result).to be_success
      expect(User.find_by(id: regular_user.id)).to be_nil
    end

    it "returns failure when user not found" do
      result = described_class.call(user_id: 999, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it "returns failure when trying to delete an admin" do
      another_admin = create(:user, role: :admin)
      result = described_class.call(user_id: another_admin.id, admin: admin)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
    end

    it "removes the user's audit logs before deletion" do
      AuditLog.create!(user_id: regular_user.id, action: "user_logged_in")
      described_class.call(user_id: regular_user.id, admin: admin)
      expect(AuditLog.where(user_id: regular_user.id).where(action: "user_logged_in")).to be_empty
    end

    it "publishes Identity::Events::UserDeleted event" do
      handler = double("handler")
      allow(handler).to receive(:call)
      EventBus.subscribe(Identity::Events::UserDeleted, handler)

      described_class.call(user_id: regular_user.id, admin: admin)
      expect(handler).to have_received(:call).with(an_instance_of(Identity::Events::UserDeleted))
    end
  end
end
