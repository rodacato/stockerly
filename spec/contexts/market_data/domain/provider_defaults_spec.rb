require "rails_helper"

RSpec.describe MarketData::Domain::ProviderDefaults do
  # ADR-017 caps Yahoo below anything it publishes, because the bridge reaches
  # an unsanctioned surface through a browser-impersonating client. The daily
  # half of that cap was never set, so the restraint did not exist.
  it "caps Yahoo at the rate ADR-017 committed to, daily half included" do
    expect(described_class.for("Yahoo Finance"))
      .to include(max_requests_per_minute: 6, daily_call_limit: 200)
  end

  it "leaves a provider that publishes no daily cap without an invented one" do
    expect(described_class.for("DataBursatil")[:max_requests_per_minute]).to be_nil
  end

  it "falls back rather than raising for a provider it does not know" do
    expect(described_class.for("Nobody")).to eq(described_class::FALLBACK)
  end
end
