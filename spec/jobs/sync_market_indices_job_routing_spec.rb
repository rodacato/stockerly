require "rails_helper"

RSpec.describe SyncMarketIndicesJob, "routing by market" do
  let(:bursatil) { instance_double(MarketData::Gateways::DataBursatilGateway) }
  let(:bridge)   { instance_double(MarketData::Gateways::YfinanceGateway) }

  before do
    EventBus.clear!
    allow(MarketData::Gateways::DataBursatilGateway).to receive(:new).and_return(bursatil)
    allow(MarketData::Gateways::YfinanceGateway).to receive(:new).and_return(bridge)
    allow(MarketHours).to receive(:us_market_open?).and_return(true)
    allow(MarketHours).to receive(:bmv_market_open?).and_return(true)
    allow(ApiKeyResolver).to receive(:for).and_call_original
    allow(ApiKeyResolver).to receive(:for)
      .with(MarketData::Gateways::DataBursatilGateway::PROVIDER).and_return("a-token")

    create(:market_index, symbol: "IPC", name: "NAFTRAC · sigue al IPC", change_percent: 0)
    create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: 0)
  end

  # ADR-021 tolerates MarketIndex#change_percent being the provider's own field
  # only because each index has one provider. A chain would reintroduce the
  # drift that ADR closed for assets, so each gateway is asked for its own.
  it "asks each provider only for the indices it serves" do
    expect(bursatil).to receive(:fetch_index_quotes).with(%w[IPC])
      .and_return(Dry::Monads::Success([]))
    expect(bridge).to receive(:fetch_index_quotes).with(%w[SPX NDX DJI UKX VIX])
      .and_return(Dry::Monads::Success([]))

    described_class.perform_now
  end

  it "writes the IPC's day change from the BMV route" do
    allow(bursatil).to receive(:fetch_index_quotes).and_return(
      Dry::Monads::Success([ { symbol: "IPC", value: nil, change_percent: 1.25, is_open: true } ])
    )
    allow(bridge).to receive(:fetch_index_quotes).and_return(Dry::Monads::Success([]))

    described_class.perform_now

    ipc = MarketIndex.find_by(symbol: "IPC")
    expect(ipc.change_percent).to eq(1.25)
    expect(ipc.is_open).to be(true)
  end

  it "leaves the IPC without a level, because an ETF price is not an index level" do
    allow(bursatil).to receive(:fetch_index_quotes).and_return(
      Dry::Monads::Success([ { symbol: "IPC", value: nil, change_percent: 1.25, is_open: true } ])
    )
    allow(bridge).to receive(:fetch_index_quotes).and_return(Dry::Monads::Success([]))

    described_class.perform_now

    expect(MarketIndex.find_by(symbol: "IPC").value).to be_nil
  end

  it "still updates the US indices when the BMV route fails" do
    allow(bursatil).to receive(:fetch_index_quotes)
      .and_return(Dry::Monads::Failure([ :not_found, "no proxy quote" ]))
    allow(bridge).to receive(:fetch_index_quotes).and_return(
      Dry::Monads::Success([ { symbol: "SPX", value: 6_000, change_percent: -0.4, is_open: true } ])
    )

    described_class.perform_now

    expect(MarketIndex.find_by(symbol: "SPX").change_percent).to eq(-0.4)
  end

  it "does not let one route raising take the other down" do
    allow(bursatil).to receive(:fetch_index_quotes).and_raise(StandardError, "token rejected")
    allow(bridge).to receive(:fetch_index_quotes).and_return(
      Dry::Monads::Success([ { symbol: "SPX", value: 6_000, change_percent: -0.4, is_open: true } ])
    )

    expect { described_class.perform_now }.not_to raise_error
    expect(MarketIndex.find_by(symbol: "SPX").change_percent).to eq(-0.4)
  end

  it "logs a failure when no route returns anything" do
    allow(bursatil).to receive(:fetch_index_quotes).and_return(Dry::Monads::Success([]))
    allow(bridge).to receive(:fetch_index_quotes).and_return(Dry::Monads::Success([]))

    described_class.perform_now

    expect(SystemLog.where(severity: :error).last.error_message).to include("No index quotes")
  end

  # An instance with no DataBursatil token keeps the index it had rather than
  # losing it, and the choice is made by configuration so it cannot flip
  # between syncs (ADR-021).
  context "when DataBursatil is not configured" do
    before do
      allow(ApiKeyResolver).to receive(:for)
        .with(MarketData::Gateways::DataBursatilGateway::PROVIDER).and_return(nil)
    end

    it "asks the bridge for the IPC as well, and never builds the BMV gateway" do
      expect(MarketData::Gateways::DataBursatilGateway).not_to receive(:new)
      expect(bridge).to receive(:fetch_index_quotes)
        .with(%w[SPX NDX DJI UKX VIX IPC]).and_return(Dry::Monads::Success([]))

      described_class.perform_now
    end

    it "logs no error for the missing token, because absent is not broken" do
      allow(bridge).to receive(:fetch_index_quotes).and_return(
        Dry::Monads::Success([ { symbol: "IPC", value: 52_180.5, change_percent: -0.3, is_open: true } ])
      )

      expect { described_class.perform_now }.not_to change(SystemLog.where(severity: :error), :count)
    end
  end
end
