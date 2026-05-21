require "rails_helper"

RSpec.describe TechnicalObservation, type: :model do
  describe "validations" do
    it "requires observation_type" do
      observation = build(:technical_observation, observation_type: nil)
      expect(observation).not_to be_valid
      expect(observation.errors[:observation_type]).to be_present
    end

    it "requires observed_at" do
      observation = build(:technical_observation, observed_at: nil)
      expect(observation).not_to be_valid
      expect(observation.errors[:observed_at]).to be_present
    end

    it "rejects unknown observation_type values" do
      observation = build(:technical_observation, observation_type: "made_up_thing")
      expect(observation).not_to be_valid
      expect(observation.errors[:observation_type]).to be_present
    end

    described_class::TYPES.each do |type|
      it "accepts canonical type :#{type}" do
        observation = build(:technical_observation, observation_type: type)
        expect(observation).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:asset) { create(:asset, symbol: "AAPL") }
    let!(:recent) { create(:technical_observation, asset: asset, observed_at: 2.days.ago) }
    let!(:old) { create(:technical_observation, asset: asset, observed_at: 30.days.ago) }

    it ".recent orders by observed_at DESC" do
      expect(described_class.recent.first).to eq(recent)
    end

    it ".within_last(N) filters to recent N days" do
      expect(described_class.within_last(7)).to contain_exactly(recent)
    end

    it ".for_assets filters by asset_id list" do
      other = create(:technical_observation, asset: create(:asset, symbol: "MSFT"))
      expect(described_class.for_assets([ asset.id ])).to contain_exactly(recent, old)
      expect(described_class.for_assets([ asset.id ])).not_to include(other)
    end
  end

  describe "#phrase (descriptive copy per ADR-001 — es-MX after #93)" do
    it "produces purely observational text for each canonical type" do
      # ADR-001: descriptive, never imperative. Es-MX equivalents:
      # comprar / vender / rebalancear / considera / deberías / es momento.
      imperative = /\b(comprar|vender|rebalancear|considera|considere|deberías?|debes|es momento)\b/i

      described_class::TYPES.each do |type|
        phrase = build(:technical_observation, observation_type: type).phrase
        expect(phrase).to be_a(String).and(be_present)
        expect(phrase).not_to match(imperative), "phrase '#{phrase}' for :#{type} violates ADR-001"
      end
    end

    it "matches the canonical es-MX RSI oversold phrasing exactly" do
      observation = build(:technical_observation, observation_type: "rsi_oversold_entered")
      expect(observation.phrase).to eq("entró en zona de sobreventa (RSI(14) por debajo de 30)")
    end

    it "matches the canonical es-MX MA200 cross phrasing exactly" do
      observation = build(:technical_observation, :ma200_crossed_below)
      expect(observation.phrase).to eq("cruzó a la baja su MA200")
    end
  end

  describe "#tag" do
    it "returns the uppercase es-MX category label for an RSI observation" do
      expect(build(:technical_observation, observation_type: "rsi_oversold_entered").tag).to eq("RSI")
    end

    it "returns MEDIA MÓVIL for a moving-average cross" do
      expect(build(:technical_observation, observation_type: "ma200_crossed_above").tag).to eq("MEDIA MÓVIL")
    end

    it "returns BANDAS for a Bollinger breach" do
      expect(build(:technical_observation, observation_type: "bb_upper_breached").tag).to eq("BANDAS")
    end
  end

  describe "#accent" do
    it "returns 'pos' for a bullish MA50 cross above" do
      expect(build(:technical_observation, observation_type: "ma50_crossed_above").accent).to eq("pos")
    end

    it "returns 'warn' for entering the RSI overbought zone" do
      expect(build(:technical_observation, observation_type: "rsi_overbought_entered").accent).to eq("warn")
    end
  end
end
