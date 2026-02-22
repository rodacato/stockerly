require "rails_helper"

RSpec.describe AuditLog, type: :model do
  subject(:log) { build(:audit_log) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires action" do
      log.action = nil
      expect(log).not_to be_valid
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    before do
      create(:audit_log, user: user, action: "admin.users.suspend", created_at: 1.hour.ago)
      create(:audit_log, user: user, action: "admin.assets.toggle", created_at: 2.hours.ago)
      create(:audit_log, user: create(:user), action: "admin.users.suspend", created_at: 3.hours.ago)
    end

    it ".recent orders by created_at desc" do
      expect(AuditLog.recent.first.created_at).to be > AuditLog.recent.last.created_at
    end

    it ".by_action filters by action" do
      expect(AuditLog.by_action("admin.users.suspend").count).to eq(2)
    end

    it ".by_action returns all when action is nil" do
      expect(AuditLog.by_action(nil).count).to eq(3)
    end

    it ".by_user filters by user_id" do
      expect(AuditLog.by_user(user.id).count).to eq(2)
    end

    it ".by_user returns all when user_id is nil" do
      expect(AuditLog.by_user(nil).count).to eq(3)
    end
  end

  describe "associations" do
    it "allows nil auditable (polymorphic optional)" do
      log = build(:audit_log, auditable: nil)
      expect(log).to be_valid
    end
  end
end
