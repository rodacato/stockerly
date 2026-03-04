require "rails_helper"

RSpec.describe MarketData::Gateways::ApiKeyNotConfiguredError do
  it "includes provider name in message" do
    error = described_class.new("Polygon.io")

    expect(error.message).to include("Polygon.io")
    expect(error.message).to include("not configured")
  end

  it "includes reason when provided" do
    error = described_class.new("FMP", reason: "decryption failed")

    expect(error.message).to include("FMP")
    expect(error.message).to include("decryption failed")
  end

  it "is a StandardError" do
    expect(described_class.superclass).to eq(StandardError)
  end
end
