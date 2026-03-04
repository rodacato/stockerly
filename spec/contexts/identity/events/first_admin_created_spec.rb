require "rails_helper"

RSpec.describe Identity::Events::FirstAdminCreated do
  it "creates event with required attributes" do
    event = described_class.new(user_id: 1, email: "admin@example.com")

    expect(event.user_id).to eq(1)
    expect(event.email).to eq("admin@example.com")
    expect(event.occurred_at).to be_present
  end

  it "has a meaningful event name" do
    event = described_class.new(user_id: 1, email: "admin@example.com")
    expect(event.event_name).to eq("identity.events.first_admin_created")
  end
end
