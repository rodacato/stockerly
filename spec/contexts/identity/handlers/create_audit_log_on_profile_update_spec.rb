require "rails_helper"

RSpec.describe Identity::Handlers::CreateAuditLogOnProfileUpdate do
  let(:user) { create(:user) }

  it "creates a minimal audit log entry pointing to the user" do
    event = Identity::Events::ProfileUpdated.new(user_id: user.id)

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.action).to eq("profile_updated")
  end
end
