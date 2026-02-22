require "rails_helper"

RSpec.describe Profiles::ChangePasswordContract do
  subject(:contract) { described_class.new }

  it "succeeds with valid params" do
    result = contract.call(current_password: "old12345", password: "newpass88", password_confirmation: "newpass88")
    expect(result).to be_success
  end

  it "fails when current_password is missing" do
    result = contract.call(current_password: "", password: "newpass88", password_confirmation: "newpass88")
    expect(result.errors[:current_password]).to be_present
  end

  it "fails when password is too short" do
    result = contract.call(current_password: "old12345", password: "short", password_confirmation: "short")
    expect(result.errors[:password]).to be_present
  end

  it "fails when confirmation does not match" do
    result = contract.call(current_password: "old12345", password: "newpass88", password_confirmation: "different")
    expect(result.errors[:password_confirmation]).to be_present
  end
end
