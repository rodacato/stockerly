require "rails_helper"

RSpec.describe MarketData::Contracts::LlmResponseContract do
  subject(:contract) { described_class.new }

  it "passes with valid content and provider" do
    result = contract.call(content: "Analysis text", provider: "anthropic")
    expect(result).to be_success
  end

  it "fails when content exceeds 5000 characters" do
    result = contract.call(content: "x" * 5001, provider: "anthropic")
    expect(result).to be_failure
    expect(result.errors[:content]).to include("must be at most 5000 characters")
  end
end
