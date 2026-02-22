require "rails_helper"

RSpec.describe CreateAuditLogOnSuspension do
  let(:admin) { create(:user, role: :admin) }
  let(:user) { create(:user) }

  it "creates an audit log entry" do
    event = UserSuspended.new(user_id: user.id, email: user.email, admin_id: admin.id)

    expect {
      described_class.call(event)
    }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("user_suspended")
    expect(log.changes_data["suspended_user_id"]).to eq(user.id)
  end
end
