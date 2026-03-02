require "rails_helper"

RSpec.describe Trading::WeeklyInsightCalculator do
  # Lightweight structs to avoid DB dependency (pure domain service)
  Snapshot = Struct.new(:total_value, keyword_init: true)
  PositionAsset = Struct.new(:symbol, :change_percent_24h, keyword_init: true)
  FakePosition = Struct.new(:asset, keyword_init: true)

  describe ".calculate" do
    it "returns has_data false with empty snapshots" do
      result = described_class.calculate(snapshots: [], positions: [])
      expect(result[:has_data]).to be false
      expect(result[:weekly_change]).to be_nil
      expect(result[:summary_text]).to be_nil
    end

    it "returns has_data false with fewer than 2 snapshots" do
      snapshots = [ Snapshot.new(total_value: 10_000) ]
      result = described_class.calculate(snapshots: snapshots, positions: [])
      expect(result[:has_data]).to be false
    end

    it "calculates positive weekly change from snapshots" do
      snapshots = [
        Snapshot.new(total_value: 10_000),
        Snapshot.new(total_value: 10_500)
      ]
      result = described_class.calculate(snapshots: snapshots, positions: [])
      expect(result[:has_data]).to be true
      expect(result[:weekly_change]).to eq(5.0)
    end

    it "calculates negative weekly change from snapshots" do
      snapshots = [
        Snapshot.new(total_value: 10_000),
        Snapshot.new(total_value: 9_500)
      ]
      result = described_class.calculate(snapshots: snapshots, positions: [])
      expect(result[:has_data]).to be true
      expect(result[:weekly_change]).to eq(-5.0)
    end

    it "identifies top and worst performer from positions" do
      positions = [
        FakePosition.new(asset: PositionAsset.new(symbol: "AAPL", change_percent_24h: 3.5)),
        FakePosition.new(asset: PositionAsset.new(symbol: "TSLA", change_percent_24h: -2.1)),
        FakePosition.new(asset: PositionAsset.new(symbol: "NVDA", change_percent_24h: 1.0))
      ]
      snapshots = [
        Snapshot.new(total_value: 10_000),
        Snapshot.new(total_value: 10_200)
      ]

      result = described_class.calculate(snapshots: snapshots, positions: positions)
      expect(result[:top_performer]).to eq({ symbol: "AAPL", change: 3.5 })
      expect(result[:worst_performer]).to eq({ symbol: "TSLA", change: -2.1 })
    end

    it "generates observational summary text without imperative advice" do
      positions = [
        FakePosition.new(asset: PositionAsset.new(symbol: "AAPL", change_percent_24h: 3.5))
      ]
      snapshots = [
        Snapshot.new(total_value: 10_000),
        Snapshot.new(total_value: 10_250)
      ]

      result = described_class.calculate(snapshots: snapshots, positions: positions)
      expect(result[:summary_text]).to include("Your portfolio was up 2.5% this week")
      expect(result[:summary_text]).to include("Top performer: AAPL (+3.5%)")
      expect(result[:summary_text]).not_to match(/consider|should|buy|sell|diversif/i)
    end
  end
end
