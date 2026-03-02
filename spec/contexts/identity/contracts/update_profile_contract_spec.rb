require "rails_helper"

RSpec.describe Identity::Contracts::UpdateProfileContract do
  subject(:contract) { described_class.new }

  it "succeeds with valid params" do
    result = contract.call(full_name: "Alex Trader", email: "alex@example.com")
    expect(result).to be_success
  end

  it "fails with empty full_name" do
    result = contract.call(full_name: "", email: "alex@example.com")
    expect(result.errors[:full_name]).to be_present
  end

  it "fails with full_name shorter than 2 chars" do
    result = contract.call(full_name: "A", email: "alex@example.com")
    expect(result.errors[:full_name]).to be_present
  end

  it "fails with invalid email format" do
    result = contract.call(full_name: "Alex", email: "not-an-email")
    expect(result.errors[:email]).to be_present
  end
end
