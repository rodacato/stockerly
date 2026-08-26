require "rails_helper"

RSpec.describe MarketData::Queries::PriceSeries do
  let(:asset) { create(:asset, symbol: "AAPL") }

  def bar(days_ago, close:, interval: "1d", volume: 1_000)
    create(:asset_price_history, asset: asset, date: days_ago.days.ago.to_date,
                                 close: close, interval: interval, volume: volume)
  end

  describe "#all" do
    it "returns rows oldest first" do
      bar(1, close: 102)
      bar(3, close: 100)

      expect(described_class.for(asset).all.map(&:close)).to eq([ 100, 102 ].map(&:to_d))
    end

    # The unique index grew to include interval so an intraday series can live
    # beside a daily one; a daily read must not pick the intraday rows up.
    it "does not mix intervals" do
      bar(1, close: 102)
      bar(1, close: 999, interval: "5m")

      expect(described_class.for(asset).all.map(&:close)).to eq([ 102.to_d ])
      expect(described_class.for(asset, interval: "5m").all.map(&:close)).to eq([ 999.to_d ])
    end
  end

  describe "#latest" do
    it "returns the last rows in chronological order" do
      bar(1, close: 103)
      bar(2, close: 102)
      bar(5, close: 100)

      expect(described_class.for(asset).latest(2).map(&:close)).to eq([ 102, 103 ].map(&:to_d))
    end

    # An eager-loaded detail page should not pay for a second query.
    it "uses the association when it is already loaded" do
      bar(1, close: 103)
      bar(2, close: 102)
      loaded = Asset.includes(:asset_price_histories).find(asset.id)

      queries = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        queries += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ])
      end

      result = described_class.for(loaded).latest(2)
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(result.map(&:close)).to eq([ 102, 103 ].map(&:to_d))
      expect(queries).to eq(0)
    end
  end

  describe "#since and #between" do
    it "bounds the range inclusively" do
      bar(1, close: 103)
      bar(10, close: 100)

      expect(described_class.for(asset).since(5.days.ago.to_date).map(&:close)).to eq([ 103.to_d ])
      expect(described_class.for(asset).between(20.days.ago.to_date, Date.current).size).to eq(2)
    end
  end

  describe "#average_volume" do
    it "averages only the window asked for" do
      bar(1, close: 103, volume: 200)
      bar(3, close: 102, volume: 400)
      bar(60, close: 100, volume: 10_000)

      expect(described_class.for(asset).average_volume(30)).to eq(300)
    end

    it "returns zero rather than nil when there is nothing to average" do
      expect(described_class.for(asset).average_volume(30)).to eq(0)
    end
  end

  describe "#closes_by_date" do
    it "maps date to close" do
      bar(1, close: 103)

      expect(described_class.for(asset).closes_by_date).to eq({ 1.day.ago.to_date => 103.to_d })
    end
  end
end
