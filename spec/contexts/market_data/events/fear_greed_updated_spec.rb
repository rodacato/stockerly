require "rails_helper"

RSpec.describe MarketData::FearGreedUpdated do
  it "has required attributes" do
    event = described_class.new(index_type: "crypto", value: 25, classification: "Extreme Fear")

    expect(event.index_type).to eq("crypto")
    expect(event.value).to eq(25)
    expect(event.classification).to eq("Extreme Fear")
    expect(event.occurred_at).to be_present
  end
end
