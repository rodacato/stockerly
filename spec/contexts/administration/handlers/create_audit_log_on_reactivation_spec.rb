require "rails_helper"

RSpec.describe Administration::Handlers::CreateAuditLogOnReactivation do
  let(:admin) { create(:user, role: :admin) }
  let(:user) { create(:user) }

  it "creates an audit log entry" do
    event = Identity::Events::UserReactivated.new(user_id: user.id, email: user.email, admin_id: admin.id)

    expect {
      described_class.call(event)
    }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("user_reactivated")
    expect(log.changes_data["reactivated_user_id"]).to eq(user.id)
  end
end
