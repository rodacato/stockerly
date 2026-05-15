require "rails_helper"

RSpec.describe MarketData::UseCases::DetectTechnicalObservations do
  subject(:use_case) { described_class.new }

  # Builds N price history rows oldest → newest with given closes
  def seed_history(asset, closes)
    closes.each_with_index do |close, i|
      create(:asset_price_history, asset: asset, date: (closes.size - i).days.ago.to_date, close: close)
    end
  end

  describe "#call" do
    it "returns Success(0) when no assets have sufficient history" do
      create(:asset, symbol: "TINY", current_price: 100)
      result = use_case.call
      expect(result).to be_success
      expect(result.value!).to eq(0)
    end

    it "skips assets with nil current_price (dead listings)" do
      asset = create(:asset, symbol: "DEAD", current_price: nil)
      seed_history(asset, (1..40).map { |i| 100.0 - i }) # would otherwise trigger
      expect { use_case.call }.not_to change(TechnicalObservation, :count)
    end
  end

  describe "RSI transitions" do
    let!(:asset) { create(:asset, symbol: "AAPL", current_price: 145.0) }

    it "fires rsi_oversold_entered when RSI crosses below 30" do
      # 15 flat closes at 100 (yesterday's window: RSI=50, neutral), then
      # a single catastrophic drop on the last day → today's window has
      # 13 zero deltas and 1 huge loss → RSI bottoms out at 0.
      flat = Array.new(15, 100.0)
      crash = 10.0
      seed_history(asset, flat + [ crash ])

      use_case.call
      expect(TechnicalObservation.where(observation_type: "rsi_oversold_entered", asset: asset)).to exist
    end

    it "fires rsi_oversold_exited when RSI crosses back above 30" do
      # 15 monotonically declining closes (yesterday: all losses → RSI≈0),
      # then a strong rebound on the last day → today's window includes
      # one big gain → RSI crosses back above 30.
      declining = (1..15).map { |i| 100.0 - i * 4 }
      rebound = 80.0
      seed_history(asset, declining + [ rebound ])

      use_case.call
      expect(TechnicalObservation.where(observation_type: "rsi_oversold_exited", asset: asset)).to exist
    end
  end

  describe "MA crossings" do
    let!(:asset) { create(:asset, symbol: "MSFT", current_price: 410.0) }

    it "fires ma50_crossed_above when price crosses above MA50" do
      # 50 closes around 100 (MA50 ≈ 100), close[-2] below, close[-1] above.
      base = Array.new(50, 100.0)
      tail = [ 95.0, 110.0 ] # prev close 95 (below avg), current close 110 (above)
      seed_history(asset, base + tail)

      use_case.call
      expect(TechnicalObservation.where(observation_type: "ma50_crossed_above", asset: asset)).to exist
    end

    it "fires ma50_crossed_below when price crosses below MA50" do
      base = Array.new(50, 100.0)
      tail = [ 105.0, 90.0 ]
      seed_history(asset, base + tail)

      use_case.call
      expect(TechnicalObservation.where(observation_type: "ma50_crossed_below", asset: asset)).to exist
    end

    it "skips MA200 when fewer than 201 closes exist (graceful degradation)" do
      seed_history(asset, (1..100).map { 100.0 })
      use_case.call
      expect(TechnicalObservation.where(observation_type: [ "ma200_crossed_above", "ma200_crossed_below" ], asset: asset)).not_to exist
    end
  end

  describe "Bollinger Band breaches" do
    let!(:asset) { create(:asset, symbol: "NVDA", current_price: 200.0) }

    it "fires bb_upper_breached on a close above the upper band" do
      base = Array.new(20, 100.0) # flat → bb_upper == 100
      tail = [ 99.0, 130.0 ]      # prev within, current well above
      seed_history(asset, base + tail)

      use_case.call
      expect(TechnicalObservation.where(observation_type: "bb_upper_breached", asset: asset)).to exist
    end
  end

  describe "dedup window" do
    let!(:asset) { create(:asset, symbol: "TSLA", current_price: 200.0) }

    before do
      base = Array.new(50, 100.0)
      tail = [ 95.0, 110.0 ]
      seed_history(asset, base + tail)
    end

    it "does not re-emit the same (asset, type) within DEDUP_WINDOW_DAYS" do
      use_case.call
      expect { use_case.call }.not_to change(TechnicalObservation, :count)
    end

    it "re-emits once the cooldown window has passed" do
      use_case.call
      TechnicalObservation.last.update_columns(observed_at: 8.days.ago)
      expect { use_case.call }.to change(TechnicalObservation, :count).by(1)
    end
  end
end
