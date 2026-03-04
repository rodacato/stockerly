require "rails_helper"

RSpec.describe Identity::Contracts::CreateFirstAdminContract do
  subject(:contract) { described_class.new }

  let(:valid_params) do
    {
      full_name: "Admin User",
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  it "passes with valid params" do
    result = contract.call(valid_params)
    expect(result).to be_success
  end

  it "fails with missing full_name" do
    result = contract.call(valid_params.except(:full_name))
    expect(result.errors[:full_name]).to be_present
  end

  it "fails with short full_name" do
    result = contract.call(valid_params.merge(full_name: "A"))
    expect(result.errors[:full_name]).to be_present
  end

  it "fails with invalid email" do
    result = contract.call(valid_params.merge(email: "not-an-email"))
    expect(result.errors[:email]).to be_present
  end

  it "fails with short password" do
    result = contract.call(valid_params.merge(password: "short", password_confirmation: "short"))
    expect(result.errors[:password]).to be_present
  end

  it "fails with mismatched password confirmation" do
    result = contract.call(valid_params.merge(password_confirmation: "different"))
    expect(result.errors[:password_confirmation]).to be_present
  end
end
