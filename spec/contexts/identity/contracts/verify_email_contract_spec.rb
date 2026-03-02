require "rails_helper"

RSpec.describe Identity::Contracts::VerifyEmailContract do
  subject(:contract) { described_class.new }

  it "passes with valid token" do
    result = contract.call(token: "valid-token-string")
    expect(result).to be_success
  end

  it "fails with empty token" do
    result = contract.call(token: "")
    expect(result).to be_failure
    expect(result.errors[:token]).to be_present
  end

  it "fails with missing token" do
    result = contract.call({})
    expect(result).to be_failure
    expect(result.errors[:token]).to be_present
  end
end
