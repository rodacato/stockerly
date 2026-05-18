require "rails_helper"

RSpec.describe Identity::Contracts::RegisterContract do
  subject(:contract) { described_class.new }

  let(:valid_params) do
    {
      full_name: "John Doe",
      email: "john@example.com",
      password: "password123",
      password_confirmation: "password123",
      invite_code: "a3f89c2e4b1d",
      consents_data_processing: true
    }
  end

  it "passes with valid params" do
    result = contract.call(valid_params)
    expect(result).to be_success
  end

  it "fails with missing full_name" do
    result = contract.call(valid_params.merge(full_name: ""))
    expect(result).to be_failure
    expect(result.errors[:full_name]).to be_present
  end

  it "fails with short full_name" do
    result = contract.call(valid_params.merge(full_name: "A"))
    expect(result).to be_failure
    expect(result.errors[:full_name]).to be_present
  end

  it "fails with invalid email" do
    result = contract.call(valid_params.merge(email: "not-valid"))
    expect(result).to be_failure
    expect(result.errors[:email]).to be_present
  end

  it "fails with short password" do
    result = contract.call(valid_params.merge(password: "short", password_confirmation: "short"))
    expect(result).to be_failure
    expect(result.errors[:password]).to be_present
  end

  it "fails with mismatched confirmation" do
    result = contract.call(valid_params.merge(password_confirmation: "different123"))
    expect(result).to be_failure
    expect(result.errors[:password_confirmation]).to be_present
  end

  it "fails with missing invite_code" do
    result = contract.call(valid_params.except(:invite_code))
    expect(result).to be_failure
    expect(result.errors[:invite_code]).to be_present
  end

  it "fails with malformed invite_code" do
    result = contract.call(valid_params.merge(invite_code: "not-hex-123!"))
    expect(result).to be_failure
    expect(result.errors[:invite_code]).to be_present
  end

  it "accepts hyphenated invite_code (normalized to 12 hex chars)" do
    result = contract.call(valid_params.merge(invite_code: "a3f8-9c2e-4b1d"))
    expect(result).to be_success
  end

  it "fails when Art. 8 consent is missing" do
    result = contract.call(valid_params.except(:consents_data_processing))
    expect(result).to be_failure
    expect(result.errors[:consents_data_processing]).to be_present
  end

  it "fails when Art. 8 consent is false (not pre-checked)" do
    result = contract.call(valid_params.merge(consents_data_processing: false))
    expect(result).to be_failure
    expect(result.errors[:consents_data_processing]).to be_present
  end
end
