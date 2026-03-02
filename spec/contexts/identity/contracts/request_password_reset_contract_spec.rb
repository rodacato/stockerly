require "rails_helper"

RSpec.describe Identity::RequestPasswordResetContract do
  subject(:contract) { described_class.new }

  it "passes with valid email" do
    result = contract.call(email: "john@example.com")
    expect(result).to be_success
  end

  it "fails with missing email" do
    result = contract.call(email: "")
    expect(result).to be_failure
    expect(result.errors[:email]).to be_present
  end
end
