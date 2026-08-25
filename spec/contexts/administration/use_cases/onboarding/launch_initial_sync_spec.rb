require "rails_helper"

RSpec.describe Administration::UseCases::Onboarding::LaunchInitialSync do
  describe ".call" do
    context "when launch_sync is true" do
      before { create(:asset, asset_type: :stock) }

      it "enqueues sync jobs" do
        expect {
          described_class.call(launch_sync: true)
        }.to have_enqueued_job(SyncPriorityAssetsJob)
      end
    end

    context "when launch_sync is false" do
      it "does not enqueue sync jobs" do
        expect {
          described_class.call(launch_sync: false)
        }.not_to have_enqueued_job(SyncPriorityAssetsJob)
      end
    end

    # The write this use case used to do. Onboarding is complete when the
    # person leaves Welcome, not when the sync starts — and onboarded_at is
    # Identity's to set.
    it "does not touch onboarded_at" do
      user = create(:user, :admin, onboarded_at: nil)

      described_class.call(launch_sync: false)

      expect(user.reload.onboarded?).to be false
    end
  end
end
