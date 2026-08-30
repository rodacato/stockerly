require "rails_helper"

RSpec.describe MarketData::UseCases::SyncFxHistory do
  # A gateway double stands in for Banxico here — it is a boundary we do not
  # own. Everything below it (parsing, persistence, upsert) is exercised for
  # real against the database.
  let(:gateway) { instance_double(MarketData::Gateways::BanxicoGateway) }

  def fixes(*pairs)
    Dry::Monads::Success(pairs.map { |date, rate| { date: date, rate: rate } })
  end

  it "stores each published fix as history" do
    allow(gateway).to receive(:fetch_fx_fixes)
      .and_return(fixes([ Date.new(2026, 5, 11), 17.0 ], [ Date.new(2026, 5, 12), 17.2 ]))

    result = described_class.call(gateway: gateway)

    expect(result).to be_success
    expect(FxRateHistory.for_pair("USD", "MXN").pluck(:rate_date, :rate))
      .to contain_exactly([ Date.new(2026, 5, 11), 17.0 ], [ Date.new(2026, 5, 12), 17.2 ])
  end

  it "names the series, not just Banxico — the two FIX series disagree by date" do
    allow(gateway).to receive(:fetch_fx_fixes).and_return(fixes([ Date.new(2026, 5, 12), 17.0 ]))

    described_class.call(gateway: gateway)

    expect(FxRateHistory.last.source).to eq("Banxico/SF60653")
  end

  it "re-running a day corrects the rate instead of duplicating it" do
    allow(gateway).to receive(:fetch_fx_fixes).and_return(fixes([ Date.new(2026, 5, 12), 17.0 ]))
    described_class.call(gateway: gateway)

    allow(gateway).to receive(:fetch_fx_fixes).and_return(fixes([ Date.new(2026, 5, 12), 17.4 ]))
    described_class.call(gateway: gateway)

    expect(FxRateHistory.count).to eq(1)
    expect(FxRateHistory.first.rate).to eq(17.4)
  end

  it "asks for a window, not a single day, so a missed run heals itself" do
    expect(gateway).to receive(:fetch_fx_fixes)
      .with(hash_including(from: Date.current - described_class::DEFAULT_LOOKBACK, to: Date.current))
      .and_return(fixes([ Date.current, 17.0 ]))

    described_class.call(gateway: gateway)
  end

  it "passes the gateway's failure through instead of storing nothing quietly" do
    allow(gateway).to receive(:fetch_fx_fixes)
      .and_return(Dry::Monads::Failure([ :gateway_error, "Banxico returned 503" ]))

    result = described_class.call(gateway: gateway)

    expect(result).to be_failure
    expect(result.failure).to eq([ :gateway_error, "Banxico returned 503" ])
    expect(FxRateHistory.count).to eq(0)
  end
  # Banxico blocks an abusing token for a full calendar day, and the same token
  # serves CETES — so the direct call needs the breaker its registry declares.
  describe "under its circuit breaker" do
    it "does not reach Banxico once the breaker is open" do
      breaker = GatewayChain.breaker_for("banxico")
      5.times { breaker.call { Dry::Monads::Failure([ :gateway_error, "boom" ]) } }
      expect(breaker.state).to eq(:open)

      gateway = instance_double(MarketData::Gateways::BanxicoGateway)
      allow(gateway).to receive(:fetch_fx_fixes)

      result = described_class.call(from: Date.current - 3, to: Date.current, gateway: gateway)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:circuit_open)
      expect(gateway).not_to have_received(:fetch_fx_fixes)
    end
  end
end
