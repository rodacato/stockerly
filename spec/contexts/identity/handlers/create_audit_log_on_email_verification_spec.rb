require "rails_helper"

RSpec.describe Identity::Handlers::CreateAuditLogOnEmailVerification do
  let(:user) { create(:user) }

  it "creates an audit log entry with the verified email" do
    event = Identity::Events::EmailVerified.new(user_id: user.id, email: user.email)

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.action).to eq("email_verified")
    expect(log.changes_data["email"]).to eq(user.email)
  end
end
