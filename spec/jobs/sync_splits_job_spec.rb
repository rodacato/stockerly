require "rails_helper"

RSpec.describe SyncSplitsJob, type: :job do
  let(:gateway) { instance_double(FmpGateway) }
  let(:asset) { create(:asset, :stock) }
  let(:portfolio) { create(:portfolio) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, status: :open) }

  before do
    allow(FmpGateway).to receive(:new).and_return(gateway)
  end

  it "creates stock splits from FMP data" do
    split_data = [
      { date: Date.new(2026, 2, 15), numerator: 4, denominator: 1 }
    ]
    allow(gateway).to receive(:fetch_splits).with(asset.symbol)
      .and_return(Dry::Monads::Success(split_data))

    expect { described_class.perform_now }.to change(StockSplit, :count).by(1)
  end

  it "publishes Trading::SplitDetected for new splits" do
    split_data = [
      { date: Date.new(2026, 2, 20), numerator: 2, denominator: 1 }
    ]
    allow(gateway).to receive(:fetch_splits)
      .and_return(Dry::Monads::Success(split_data))

    handler = class_double(Trading::AdjustPositionsOnSplit, call: nil)
    EventBus.subscribe(Trading::SplitDetected, handler)

    described_class.perform_now

    expect(handler).to have_received(:call).with(an_instance_of(Trading::SplitDetected))
  end

  it "skips already-known splits" do
    create(:stock_split, asset: asset, ex_date: Date.new(2026, 1, 10), ratio_from: 1, ratio_to: 3)
    split_data = [
      { date: Date.new(2026, 1, 10), numerator: 3, denominator: 1 }
    ]
    allow(gateway).to receive(:fetch_splits)
      .and_return(Dry::Monads::Success(split_data))

    expect { described_class.perform_now }.not_to change(StockSplit, :count)
  end
end
