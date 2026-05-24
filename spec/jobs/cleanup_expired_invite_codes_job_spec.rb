require "rails_helper"

RSpec.describe CleanupExpiredInviteCodesJob, type: :job do
  describe "#perform" do
    it "is a no-op when there are no expired-unused codes" do
      _fresh = create(:invite_code)
      _used  = create(:invite_code, :used)

      expect { described_class.new.perform }.not_to change(SystemLog, :count)
    end

    it "logs a single SystemLog entry summarising codes that expired in the last cycle" do
      # Default :expired trait sets expires_at to 1.day.ago — inside the 24h cycle window
      create_list(:invite_code, 3, :expired)

      expect { described_class.new.perform }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("InviteCode Cleanup")
      expect(log.module_name).to eq("identity")
      expect(log).to be_success
      expect(log.error_message).to include("3 invite code(s) expired")
    end

    it "ignores codes that expired BEFORE the current cycle (no redundant daily noise)" do
      old_expired = create(:invite_code)
      old_expired.update_column(:expires_at, 5.days.ago)

      expect { described_class.new.perform }.not_to change(SystemLog, :count)
    end

    it "ignores expired-AND-used codes (they already served their purpose)" do
      used = create(:invite_code, :used)
      used.update_column(:expires_at, 1.hour.ago)

      expect { described_class.new.perform }.not_to change(SystemLog, :count)
    end
  end
end
