require "rails_helper"

RSpec.describe DiscoverHelper, type: :helper do
  def wave(vs_baseline)
    MarketData::Discover::WaveRanking::Wave.new(symbol: "SMH", name: "Semiconductores", group: "sectores",
                                                 change_percent: 8.4, vs_baseline: vs_baseline, closes: [], referents: [])
  end

  describe "#wave_vs_baseline" do
    it "signs a basket that beat the baseline" do
      expect(helper.wave_vs_baseline(wave(5.2))).to eq("vs SPY +5.2")
    end

    it "uses the typographic minus for one that trailed it" do
      expect(helper.wave_vs_baseline(wave(-0.24))).to eq("vs SPY −0.2")
    end
  end
end
