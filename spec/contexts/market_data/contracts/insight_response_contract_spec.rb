require "rails_helper"

RSpec.describe MarketData::Contracts::InsightResponseContract do
  subject(:contract) { described_class.new }

  it "passes with valid summary and observations" do
    result = contract.call(summary: "Portfolio looks healthy", observations: [ "Tech heavy", "Good growth" ])
    expect(result).to be_success
  end

  it "fails when observations exceed 5 items" do
    result = contract.call(summary: "Summary", observations: Array.new(6, "observation"))
    expect(result).to be_failure
    expect(result.errors[:observations]).to include("must have at most 5 items")
  end
end
