require "rails_helper"

RSpec.describe WarmDiscoverJob, type: :job do
  let(:gateway) { instance_double(MarketData::Gateways::AlpacaGateway) }

  def bars_for(symbols)
    symbols.index_with do |_symbol|
      [ { date: 8.days.ago.to_date, close: 100.0 }, { date: Date.current, close: 110.0 } ]
    end
  end

  # The test env runs :null_store, and D31's contract makes the cache this
  # screen's only storage — so without a real one these specs would pass
  # against nothing.
  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(MarketData::Gateways::AlpacaGateway).to receive(:new).and_return(gateway)
    allow(gateway).to receive(:fetch_daily_bars)
      .and_return(Dry::Monads::Success(bars_for(MarketData::Discover::BasketCatalogue.symbols)))
  end

  it "asks for every basket and the baseline in one call" do
    described_class.perform_now

    expect(gateway).to have_received(:fetch_daily_bars)
      .with(MarketData::Discover::BasketCatalogue.symbols, anything, anything)
  end

  it "writes the ranked waves to the cache" do
    described_class.perform_now

    cached = Rails.cache.read(described_class::CACHE_KEY)
    expect(cached[:waves].map(&:symbol)).to include("SMH")
    expect(cached[:generated_at]).to be_present
  end

  # Clause 1 of the disposability contract: zero tables, zero rows.
  it "persists nothing to the database" do
    expect { described_class.perform_now }.not_to change(Asset, :count)
  end

  describe "the window it asks for" do
    it "starts at the last visit when there was one" do
      Rails.cache.write("discover:last_seen", 20.days.ago)

      described_class.perform_now

      expect(gateway).to have_received(:fetch_daily_bars)
        .with(anything, 20.days.ago.to_date, anything)
    end

    it "caps a long absence so the call stays predictable" do
      Rails.cache.write("discover:last_seen", 300.days.ago)

      described_class.perform_now

      expect(gateway).to have_received(:fetch_daily_bars)
        .with(anything, 90.days.ago.to_date, anything)
    end

    it "keeps a readable floor for someone who visited yesterday" do
      Rails.cache.write("discover:last_seen", 1.day.ago)

      described_class.perform_now

      expect(gateway).to have_received(:fetch_daily_bars)
        .with(anything, 7.days.ago.to_date, anything)
    end

    it "falls back to the cap on a first run, when nobody has visited" do
      described_class.perform_now

      expect(gateway).to have_received(:fetch_daily_bars)
        .with(anything, 90.days.ago.to_date, anything)
    end
  end

  it "leaves the previous waves in place when the provider fails" do
    Rails.cache.write(described_class::CACHE_KEY, { waves: [ :stale ] })
    allow(gateway).to receive(:fetch_daily_bars)
      .and_return(Dry::Monads::Failure([ :rate_limited, "slow down" ]))

    described_class.perform_now

    expect(Rails.cache.read(described_class::CACHE_KEY)[:waves]).to eq([ :stale ])
  end
end
