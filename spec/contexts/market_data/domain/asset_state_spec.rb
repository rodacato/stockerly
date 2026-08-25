require "rails_helper"

# ADR-014 requires the catalogue to be a closed set derived deterministically
# from persisted observations. These specs are that requirement.
RSpec.describe MarketData::Domain::AssetState do
  let(:asset) { create(:asset, :stock, symbol: "NVDA") }

  def observe(type, at: Time.current)
    TechnicalObservation.create!(asset: asset, observation_type: type, observed_at: at,
                                 indicator_snapshot: { rsi: 72 })
  end

  describe ".for" do
    it "reads overbought and an upper-band breach as stretched" do
      expect(described_class.for([ observe("rsi_overbought_entered") ])).to eq(:stretched)
      expect(described_class.for([ observe("bb_upper_breached") ])).to eq(:stretched)
    end

    it "reads oversold and a lower-band breach as oversold" do
      expect(described_class.for([ observe("rsi_oversold_entered") ])).to eq(:oversold)
      expect(described_class.for([ observe("bb_lower_breached") ])).to eq(:oversold)
    end

    # An exit is its own event, so returning to the middle needs no special case.
    it "returns to neutral once the extreme is left" do
      observations = [
        observe("rsi_overbought_entered", at: 3.days.ago),
        observe("rsi_overbought_exited", at: 1.day.ago)
      ]

      expect(described_class.for(observations)).to eq(:neutral)
    end

    it "lets the most recent observation win, whatever order it arrives in" do
      observations = [
        observe("rsi_oversold_entered", at: 1.hour.ago),
        observe("rsi_overbought_entered", at: 5.days.ago)
      ]

      expect(described_class.for(observations)).to eq(:oversold)
    end

    # A moving-average crossing is trend, not extension. It must not silence a
    # standing RSI reading just by being newer.
    it "ignores trend crossings entirely" do
      observations = [
        observe("rsi_overbought_entered", at: 2.days.ago),
        observe("ma50_crossed_above", at: 1.hour.ago)
      ]

      expect(described_class.for(observations)).to eq(:stretched)
      expect(described_class.for([ observe("ma200_crossed_below") ])).to eq(:neutral)
    end

    it "is neutral with nothing observed" do
      expect(described_class.for([])).to eq(:neutral)
      expect(described_class.for(nil)).to eq(:neutral)
    end

    it "is neutral for a type the catalogue does not know" do
      unknown = Struct.new(:observation_type, :observed_at).new("moon_phase_favourable", Time.current)

      expect(described_class.for([ unknown ])).to eq(:neutral)
    end
  end

  describe ".source" do
    it "returns the observation the state came from, so the reading can stay on screen" do
      old = observe("rsi_overbought_entered", at: 3.days.ago)
      observe("ma50_crossed_above", at: 1.hour.ago)

      expect(described_class.source([ old ])).to eq(old)
    end

    it "is nil when no observation contributed a state" do
      expect(described_class.source([ observe("ma50_crossed_above") ])).to be_nil
    end
  end

  describe ".phrase_key" do
    it "keys on the state and on whether the reader holds the asset" do
      expect(described_class.phrase_key(:stretched, holding: true)).to eq("market.estado.stretched.holding")
      expect(described_class.phrase_key(:stretched, holding: false)).to eq("market.estado.stretched.watching")
    end

    it "falls back to neutral rather than building a key for a state that does not exist" do
      expect(described_class.phrase_key(:euphoric, holding: true)).to eq("market.estado.neutral.holding")
    end

    # The catalogue is only closed if every state it names has copy behind it.
    it "resolves for every state in both readings" do
      described_class::STATES.each do |state|
        [ true, false ].each do |holding|
          expect(I18n.exists?(described_class.phrase_key(state, holding: holding))).to be(true),
                 "missing copy for #{state}/#{holding}"
        end
        expect(I18n.exists?(described_class.label_key(state))).to be(true), "missing label for #{state}"
      end
    end

    # ADR-014's own failure test, as a spec: the catalogue may not outgrow its detectors.
    it "only maps observation types the detector can persist" do
      expect(TechnicalObservation::TYPES).to include(*described_class::BY_OBSERVATION.keys)
      expect(TechnicalObservation::TYPES).to include(*described_class::TREND_ONLY)
    end
  end
end
