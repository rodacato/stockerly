require "rails_helper"

RSpec.describe MarketData::Queries::PriceSeries, ".recent_closes" do
  let(:apple) { create(:asset, :stock, symbol: "AAPL") }
  let(:nvidia) { create(:asset, :stock, symbol: "NVDA") }

  def history(asset, days_ago, close)
    create(:asset_price_history, asset: asset, date: Date.current - days_ago, close: close)
  end

  def queries
    hits = 0
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_n, _s, _f, _i, payload|
      hits += 1 if payload[:sql].include?("asset_price_histories")
    end
    yield
    hits
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end

  it "returns the last N closes per asset, oldest first" do
    5.times { |d| history(apple, d, 100 + d) }

    expect(described_class.recent_closes([ apple ], points: 3)[apple.id].map(&:to_f))
      .to eq([ 102.0, 101.0, 100.0 ])
  end

  # The whole point of X15: one statement regardless of how many assets.
  it "answers for many assets in a single query" do
    6.times { |d| history(apple, d, 100 + d) }
    6.times { |d| history(nvidia, d, 200 + d) }

    hits = queries { described_class.recent_closes([ apple, nvidia ], points: 4) }

    expect(hits).to eq(1)
  end

  it "does not let one asset's rows spill into another's" do
    6.times { |d| history(apple, d, 100 + d) }
    2.times { |d| history(nvidia, d, 200 + d) }

    result = described_class.recent_closes([ apple, nvidia ], points: 4)

    expect(result[apple.id].size).to eq(4)
    expect(result[nvidia.id].size).to eq(2)
    expect(result[nvidia.id].map(&:to_f)).to all(be >= 200)
  end

  it "omits an asset with no history rather than returning an empty entry" do
    history(apple, 0, 100)

    expect(described_class.recent_closes([ apple, nvidia ])).not_to have_key(nvidia.id)
  end

  it "accepts ids as readily as records, since the panorama holds ids" do
    3.times { |d| history(apple, d, 100 + d) }

    expect(described_class.recent_closes([ apple.id ], points: 2).keys).to eq([ apple.id ])
  end

  it "makes no query at all for an empty list" do
    expect(queries { described_class.recent_closes([]) }).to eq(0)
  end

  it "ignores intervals other than the daily one" do
    history(apple, 0, 100)
    history(apple, 1, 101)
    create(:asset_price_history, asset: apple, date: Date.current - 2, close: 999, interval: "1h")

    expect(described_class.recent_closes([ apple ], points: 5)[apple.id].map(&:to_f)).not_to include(999.0)
  end
end
