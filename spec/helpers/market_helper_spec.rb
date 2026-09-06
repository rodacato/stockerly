require "rails_helper"

RSpec.describe MarketHelper, type: :helper do
  describe "#observation_phrase (descriptive copy per ADR-001 — es-MX)" do
    it "produces purely observational text for each canonical type" do
      # ADR-001: descriptive, never imperative. Es-MX equivalents:
      # comprar / vender / rebalancear / considera / deberías / es momento.
      imperative = /\b(comprar|vender|rebalancear|considera|considere|deberías?|debes|es momento)\b/i

      TechnicalObservation::TYPES.each do |type|
        observation = build(:technical_observation, observation_type: type)
        phrase = helper.observation_phrase(observation)
        expect(phrase).to be_a(String).and(be_present)
        expect(phrase).not_to match(imperative), "phrase '#{phrase}' for :#{type} violates ADR-001"
      end
    end

    it "matches the canonical es-MX RSI oversold phrasing exactly" do
      observation = build(:technical_observation, observation_type: "rsi_oversold_entered")
      expect(helper.observation_phrase(observation)).to eq("entró en zona de sobreventa (RSI(14) por debajo de 30)")
    end

    it "matches the canonical es-MX MA200 cross phrasing exactly" do
      observation = build(:technical_observation, :ma200_crossed_below)
      expect(helper.observation_phrase(observation)).to eq("cruzó a la baja su MA200")
    end
  end

  describe "#observation_tag" do
    it "returns the uppercase es-MX category label for an RSI observation" do
      observation = build(:technical_observation, observation_type: "rsi_oversold_entered")
      expect(helper.observation_tag(observation)).to eq("RSI")
    end

    it "returns MEDIA MÓVIL for a moving-average cross" do
      observation = build(:technical_observation, observation_type: "ma200_crossed_above")
      expect(helper.observation_tag(observation)).to eq("MEDIA MÓVIL")
    end

    it "returns BANDAS for a Bollinger breach" do
      observation = build(:technical_observation, observation_type: "bb_upper_breached")
      expect(helper.observation_tag(observation)).to eq("BANDAS")
    end
  end

  describe "#observation_accent" do
    it "returns 'pos' for a bullish MA50 cross above" do
      observation = build(:technical_observation, observation_type: "ma50_crossed_above")
      expect(helper.observation_accent(observation)).to eq("pos")
    end

    it "returns 'warn' for entering the RSI overbought zone" do
      observation = build(:technical_observation, observation_type: "rsi_overbought_entered")
      expect(helper.observation_accent(observation)).to eq("warn")
    end
  end

  describe "#observation_dot_class" do
    it "maps accents to static Tailwind dot classes" do
      expect(helper.observation_dot_class("pos")).to eq("bg-emerald-500")
      expect(helper.observation_dot_class("warn")).to eq("bg-amber-500")
      expect(helper.observation_dot_class("neutral")).to eq("bg-primary")
    end
  end

  describe "#chart_anchors_json" do
    it "labels your cost with the phrase the 52-week bar already uses for it" do
      anchor = JSON.parse(helper.chart_anchors_json(172.4, "USD")).first

      expect(anchor["price"]).to eq(172.4)
      expect(anchor["label"]).to eq(
        I18n.t("market.range_52w.tu_costo", value: helper.format_currency_mx(172.4, currency: "USD"))
      )
    end

    it "draws nothing over the price when there is no position to anchor to" do
      expect(helper.chart_anchors_json(nil, "USD")).to eq("[]")
    end
  end

  describe "#chart_levels_json" do
    def layer(price, distance) = MarketData::Domain::VolatilityLayers::Layer.new(step: 1, price: price, atr_distance: distance)

    it "tells the trailing exit from an entry layer, which its price cannot" do
      levels = helper.chart_levels_json({ atr: 4.0, entries: [ layer(96.0, 1.0) ], exit: layer(88.0, 3.0) }, holding: true)

      expect(JSON.parse(levels)).to eq([
        { "price" => 96.0, "kind" => "entry" },
        { "price" => 88.0, "kind" => "exit" }
      ])
    end

    it "withholds the exit from an asset you only watch, exactly as the card does" do
      levels = helper.chart_levels_json({ atr: 4.0, entries: [ layer(96.0, 1.0) ], exit: layer(88.0, 3.0) }, holding: false)

      expect(JSON.parse(levels).pluck("kind")).to eq([ "entry" ])
    end

    it "carries only the entries when the reading produced no trailing exit" do
      levels = helper.chart_levels_json({ atr: 4.0, entries: [ layer(96.0, 1.0) ], exit: nil }, holding: true)

      expect(JSON.parse(levels).pluck("kind")).to eq([ "entry" ])
    end

    it "draws nothing when the reading carried no ATR at all" do
      expect(helper.chart_levels_json(nil)).to eq("[]")
    end
  end
end
