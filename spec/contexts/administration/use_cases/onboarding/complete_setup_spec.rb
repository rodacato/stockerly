require "rails_helper"

RSpec.describe Administration::UseCases::Onboarding::CompleteSetup do
  describe ".call" do
    let(:admin) { create(:user, :admin, onboarded_at: nil) }

    it "marks user as onboarded" do
      result = described_class.call(user: admin)

      expect(result).to be_success
      expect(admin.reload.onboarded?).to be true
    end

    context "when launch_sync is true" do
      before { create(:asset, asset_type: :stock) }

      it "enqueues sync jobs" do
        expect {
          described_class.call(user: admin, launch_sync: true)
        }.to have_enqueued_job(SyncPriorityAssetsJob)
      end
    end

    context "when launch_sync is false" do
      it "does not enqueue sync jobs" do
        expect {
          described_class.call(user: admin, launch_sync: false)
        }.not_to have_enqueued_job(SyncPriorityAssetsJob)
      end
    end
  end
end
