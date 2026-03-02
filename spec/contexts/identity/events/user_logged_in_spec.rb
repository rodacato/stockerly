require "rails_helper"

RSpec.describe Identity::UserLoggedIn do
  it "creates event with required attributes" do
    event = described_class.new(user_id: 1, ip_address: "127.0.0.1", user_agent: "Mozilla/5.0")

    expect(event.user_id).to eq(1)
    expect(event.ip_address).to eq("127.0.0.1")
    expect(event.user_agent).to eq("Mozilla/5.0")
    expect(event.occurred_at).to be_present
  end

  it "inherits from BaseEvent" do
    expect(described_class).to be < BaseEvent
  end
end
