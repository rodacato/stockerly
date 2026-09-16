require "rails_helper"

RSpec.describe MarketData::Domain::ProviderDefaults do
  # Doubled when the company overview moved onto the bridge with Alpha Vantage's
  # retirement; the per-minute restraint is unchanged.
  it "caps Yahoo at the rate ADR-017's amendments committed to" do
    expect(described_class.for("Yahoo Finance"))
      .to include(max_requests_per_minute: 30, daily_call_limit: 4_000)
  end

  it "leaves a provider that publishes no daily cap without an invented one" do
    expect(described_class.for("DataBursatil")[:max_requests_per_minute]).to be_nil
  end

  it "falls back rather than raising for a provider it does not know" do
    expect(described_class.for("Nobody")).to eq(described_class::FALLBACK)
  end
end
