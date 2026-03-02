require "rails_helper"

RSpec.describe Identity::Handlers::CreateAuditLogOnLogin do
  let!(:user) { create(:user) }

  it "creates an audit log for successful login" do
    event = Identity::Events::UserLoggedIn.new(user_id: user.id, ip_address: "192.168.1.1", user_agent: "Mozilla/5.0")

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.action).to eq("user_logged_in")
    expect(log.changes_data["ip_address"]).to eq("192.168.1.1")
    expect(log.changes_data["user_agent"]).to eq("Mozilla/5.0")
  end
end
