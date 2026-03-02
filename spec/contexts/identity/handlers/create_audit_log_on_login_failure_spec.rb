require "rails_helper"

RSpec.describe Identity::Handlers::CreateAuditLogOnLoginFailure do
  let!(:user) { create(:user, email: "target@example.com") }

  it "creates an audit log when user exists" do
    event = Identity::Events::UserLoginFailed.new(email: "target@example.com", ip_address: "10.0.0.1", user_agent: "curl/7.0")

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.action).to eq("login_failed")
    expect(log.changes_data["ip_address"]).to eq("10.0.0.1")
    expect(log.changes_data["user_agent"]).to eq("curl/7.0")
  end

  it "does not create an audit log when user does not exist" do
    event = Identity::Events::UserLoginFailed.new(email: "nobody@example.com", ip_address: "10.0.0.1", user_agent: "curl/7.0")

    expect { described_class.call(event) }.not_to change(AuditLog, :count)
  end
end
