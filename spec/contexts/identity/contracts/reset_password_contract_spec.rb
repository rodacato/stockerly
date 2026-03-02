require "rails_helper"

RSpec.describe Identity::Contracts::ResetPasswordContract do
  subject(:contract) { described_class.new }

  it "passes with valid params" do
    result = contract.call(password: "newpassword123", password_confirmation: "newpassword123")
    expect(result).to be_success
  end

  it "fails with short password" do
    result = contract.call(password: "short", password_confirmation: "short")
    expect(result).to be_failure
    expect(result.errors[:password]).to be_present
  end

  it "fails with missing confirmation" do
    result = contract.call(password: "newpassword123", password_confirmation: "")
    expect(result).to be_failure
    expect(result.errors[:password_confirmation]).to be_present
  end

  it "fails with mismatched confirmation" do
    result = contract.call(password: "newpassword123", password_confirmation: "different123")
    expect(result).to be_failure
    expect(result.errors[:password_confirmation]).to be_present
  end
end
