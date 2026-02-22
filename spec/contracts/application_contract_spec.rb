require "rails_helper"

RSpec.describe ApplicationContract do
  it "inherits from Dry::Validation::Contract" do
    expect(ApplicationContract.ancestors).to include(Dry::Validation::Contract)
  end

  it "can define params schema in subclasses" do
    test_contract = Class.new(ApplicationContract) do
      params do
        required(:email).filled(:string)
      end
    end

    result = test_contract.new.call(email: "test@example.com")
    expect(result).to be_success
  end
end
