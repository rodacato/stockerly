require "rails_helper"

RSpec.describe SyncDividendsJob, type: :job do
  let(:gateway) { instance_double(MarketData::Gateways::FmpGateway) }
  let(:asset) { create(:asset, :stock) }
  let(:portfolio) { create(:portfolio) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, status: :open) }

  before do
    allow(MarketData::Gateways::FmpGateway).to receive(:new).and_return(gateway)
  end

  it "syncs dividends for assets with open positions" do
    dividend_data = [
      { ex_date: Date.new(2026, 3, 15), pay_date: Date.new(2026, 3, 30),
        amount_per_share: 0.50, currency: "USD" }
    ]
    allow(gateway).to receive(:fetch_dividends).with(asset.symbol)
      .and_return(Dry::Monads::Success(dividend_data))

    expect { described_class.perform_now }.to change(Dividend, :count).by(1)
      .and change(DividendPayment, :count).by(1)
  end

  it "skips assets when gateway returns failure" do
    allow(gateway).to receive(:fetch_dividends)
      .and_return(Dry::Monads::Failure([ :gateway_error, "FMP error" ]))

    expect { described_class.perform_now }.not_to change(Dividend, :count)
  end

  it "publishes DividendsSynced event" do
    dividend_data = [
      { ex_date: Date.new(2026, 4, 1), pay_date: nil,
        amount_per_share: 1.25, currency: "USD" }
    ]
    allow(gateway).to receive(:fetch_dividends)
      .and_return(Dry::Monads::Success(dividend_data))

    handler = class_double(MarketData::Handlers::LogDividendsSync, call: nil)
    EventBus.subscribe(MarketData::Events::DividendsSynced, handler)

    described_class.perform_now

    expect(handler).to have_received(:call).with(an_instance_of(MarketData::Events::DividendsSynced))
  end

  it "does not duplicate existing dividends" do
    create(:dividend, asset: asset, ex_date: Date.new(2026, 5, 1), amount_per_share: 0.30)

    dividend_data = [
      { ex_date: Date.new(2026, 5, 1), pay_date: nil,
        amount_per_share: 0.30, currency: "USD" }
    ]
    allow(gateway).to receive(:fetch_dividends)
      .and_return(Dry::Monads::Success(dividend_data))

    expect { described_class.perform_now }.not_to change(Dividend, :count)
  end
end
