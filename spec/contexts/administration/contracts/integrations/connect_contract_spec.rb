require "rails_helper"

RSpec.describe Administration::Contracts::Integrations::ConnectContract do
  subject(:contract) { described_class.new }

  it "passes with valid params" do
    result = contract.call(provider_name: "IEX Cloud", provider_type: "Stocks & Forex")
    expect(result).to be_success
  end

  it "fails with missing provider_name" do
    result = contract.call(provider_name: "", provider_type: "Stocks & Forex")
    expect(result).to be_failure
    expect(result.errors[:provider_name]).to be_present
  end

  it "fails with missing provider_type" do
    result = contract.call(provider_name: "IEX Cloud", provider_type: "")
    expect(result).to be_failure
    expect(result.errors[:provider_type]).to be_present
  end
end
