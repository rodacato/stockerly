require "rails_helper"

RSpec.describe EmailVerified do
  it "creates an event with required attributes" do
    event = described_class.new(user_id: 1, email: "user@example.com")

    expect(event.user_id).to eq(1)
    expect(event.email).to eq("user@example.com")
    expect(event.occurred_at).to be_present
  end
end
