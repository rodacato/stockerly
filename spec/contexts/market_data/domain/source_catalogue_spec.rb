require "rails_helper"

RSpec.describe MarketData::Domain::SourceCatalogue do
  def integration(provider, **attrs)
    create(:integration, provider_name: provider, **attrs)
  end

  def entry_for(provider)
    described_class.all.find { |e| e.provider == provider }
  end

  describe "the four states" do
    it "reports a source with no key as no_key, not as broken" do
      integration("Finnhub", api_key_encrypted: nil, requires_api_key: true)

      expect(entry_for("Finnhub").state).to eq(:no_key)
    end

    # Our own counter stopping us. It resumes tomorrow, and saying "blocked"
    # would send the reader to the provider for a problem that is ours.
    it "reports our own exhausted budget as no_quota" do
      integration("Alpha Vantage", api_key_encrypted: "k", requires_api_key: true,
                                   daily_call_limit: 25, daily_api_calls: 25, calls_reset_at: Time.current)

      expect(entry_for("Alpha Vantage").state).to eq(:no_quota)
    end

    it "reports a provider that refused us as blocked" do
      integration("Yahoo Finance", requires_api_key: false, last_failure_tag: "rate_limited",
                                   last_failure_at: 1.hour.ago)

      expect(entry_for("Yahoo Finance").state).to eq(:blocked)
    end

    it "reports a permanent denial as blocked too" do
      integration("Finnhub", api_key_encrypted: "k", requires_api_key: true,
                             last_failure_tag: "no_entitlement", last_failure_at: 1.hour.ago)

      expect(entry_for("Finnhub").state).to eq(:blocked)
    end

    # The collision the tags cannot resolve: RateLimiter and a 429 both say
    # :rate_limited, so the counters are what decide whose limit was hit.
    it "calls our own limit no_quota even when the tag says rate_limited" do
      integration("CoinGecko", requires_api_key: false, daily_call_limit: 10, daily_api_calls: 10,
                               calls_reset_at: Time.current, last_failure_tag: "rate_limited")

      expect(entry_for("CoinGecko").state).to eq(:no_quota)
    end

    it "reports a working source as connected" do
      integration("Banxico", requires_api_key: false, daily_call_limit: 1_000, daily_api_calls: 2)

      expect(entry_for("Banxico").state).to eq(:connected)
    end
  end

  describe "quota" do
    it "carries the unit, because minutes and days are not comparable" do
      integration("Alpaca", api_key_encrypted: "k", max_requests_per_minute: 200, minute_calls: 14)

      expect(entry_for("Alpaca").quota).to have_attributes(used: 14, limit: 200, unit: :calls_per_minute)
    end

    it "asks DataBursatil for its own balance instead of counting calls" do
      integration("DataBursatil", api_key_encrypted: "k")
      allow(MarketData::Gateways::DataBursatilGateway).to receive(:quota)
        .and_return(described_class::Quota.new(used: 2_202, limit: 200_000, unit: :kib_per_month))

      expect(entry_for("DataBursatil").quota.unit).to eq(:kib_per_month)
    end

    # No bar where there is no reading: an empty bar reads as 0% used, which
    # is a number we do not have.
    it "is unknown, not zero, when the provider cannot say" do
      quota = described_class::Quota.new(used: 0, limit: nil, unit: :kib_per_month)

      expect(quota.known?).to be(false)
      expect(quota.ratio).to eq(0.0)
    end

    it "reports near_limit before exhausted so the screen can warn" do
      quota = described_class::Quota.new(used: 18, limit: 25, unit: :calls_per_day)

      expect(quota).to have_attributes(near_limit?: true, exhausted?: false)
    end
  end

  describe "roles" do
    it "calls a provider nobody can replace the only source" do
      integration("Alternative.me", requires_api_key: false)

      expect(entry_for("Alternative.me").role).to eq(:only)
    end

    # Reads the registry rather than a stored label: Alpha Vantage was the only
    # fundamentals source until FMP was scoped back to that capability, and the
    # role moved on its own.
    it "demotes a source to primary once it gains a peer" do
      integration("Alpha Vantage", api_key_encrypted: "k")

      expect(entry_for("Alpha Vantage").role).to eq(:primary)
    end

    it "calls a provider that leads a chain with a fallback the primary" do
      integration("Alpaca", api_key_encrypted: "k")

      expect(entry_for("Alpaca").role).to eq(:primary)
    end
  end

  describe ".for_capability" do
    before { %w[Finnhub Yahoo\ Finance].each { |p| integration(p, api_key_encrypted: "k") } }

    it "names the primary and its fallbacks in the order the chain tries them" do
      result = described_class.for_capability(:prices)

      expect(result[:primary].provider).to eq("Finnhub")
      expect(result[:fallbacks].map(&:provider)).to include("Yahoo Finance")
    end
  end

  it "lists only sources the registry knows, so one list drives the screen" do
    integration("Finnhub", api_key_encrypted: "k")

    expect(described_class.all.map(&:provider)).to all(be_in(DataSourceRegistry.all.map(&:integration_name)))
  end
end
