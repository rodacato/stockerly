require "rails_helper"

RSpec.describe Identity::CreateAuditLogOnPasswordChange do
  let!(:user) { create(:user) }

  it "creates an audit log for password change" do
    event = Identity::PasswordChanged.new(user_id: user.id)

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.action).to eq("password_changed")
  end
end
