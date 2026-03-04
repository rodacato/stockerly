require "rails_helper"

RSpec.describe Administration::Handlers::CreateAuditLogOnDeletion do
  let(:admin) { create(:user, role: :admin) }

  it "creates an audit log entry with deleted user info" do
    event = Identity::Events::UserDeleted.new(
      user_id: 999,
      email: "deleted@example.com",
      full_name: "Deleted User",
      admin_id: admin.id
    )

    expect {
      described_class.call(event)
    }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("user_deleted")
    expect(log.changes_data["deleted_user_id"]).to eq(999)
    expect(log.changes_data["deleted_email"]).to eq("deleted@example.com")
    expect(log.changes_data["deleted_full_name"]).to eq("Deleted User")
  end
end
