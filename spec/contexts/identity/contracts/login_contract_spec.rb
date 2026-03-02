require "rails_helper"

RSpec.describe Identity::Contracts::LoginContract do
  subject(:contract) { described_class.new }

  it "passes with valid params" do
    result = contract.call(email: "john@example.com", password: "password123")
    expect(result).to be_success
  end

  it "fails with missing email" do
    result = contract.call(email: "", password: "password123")
    expect(result).to be_failure
    expect(result.errors[:email]).to be_present
  end

  it "fails with missing password" do
    result = contract.call(email: "john@example.com", password: "")
    expect(result).to be_failure
    expect(result.errors[:password]).to be_present
  end
end
