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

  describe "#indicator_layers and #chart_layer_keys" do
    let(:indicators) do
      { rsi: [ { time: "2026-09-01", value: 61.2 } ],
        bb_upper: [ { time: "2026-09-01", value: 190.0 } ],
        bb_lower: [ { time: "2026-09-01", value: 170.0 } ] }
    end

    it "puts the RSI in its own pane and leaves the bands on the price scale" do
      layers = helper.indicator_layers(indicators)

      expect(layers.pluck(:layer)).to eq(%w[bollinger bollinger rsi])
      expect(layers.find { |layer| layer[:layer] == "rsi" }[:pane]).to eq(1)
      expect(layers.select { |layer| layer[:layer] == "bollinger" }.pluck(:pane)).to all(be_nil)
    end

    # D108: autoscaled and unnamed, the pane filled itself with whatever the
    # window held, so a quiet month drew the same picture as a real extreme.
    it "pins the RSI pane to 0-100 and names it, so its shape means something" do
      rsi = helper.indicator_layers(indicators).find { |layer| layer[:layer] == "rsi" }

      expect(rsi[:scale]).to eq(min: 0, max: 100)
      expect(rsi[:title]).to eq(I18n.t("market.precio.rsi.titulo",
                                       period: MarketData::Domain::TechnicalIndicators::RSI_PERIOD))
    end

    # The thresholds are IndicatorSignals' own, so the pane and the Senales row
    # cannot disagree about where overbought starts.
    it "draws its guides at the thresholds the Senales card already reads" do
      rsi = helper.indicator_layers(indicators).find { |layer| layer[:layer] == "rsi" }

      expect(rsi[:guides]).to eq([ MarketData::Domain::IndicatorSignals::OVERBOUGHT,
                                   MarketData::Domain::IndicatorSignals::OVERSOLD ])
    end

    it "gives the price series no pane scale of its own to override" do
      expect(helper.indicator_layers(indicators).select { |layer| layer[:layer] == "bollinger" }
                   .pluck(:scale)).to all(be_nil)
    end

    it "offers nothing outside the ranges the indicators describe" do
      expect(helper.indicator_layers(nil)).to be_empty
      expect(helper.chart_layer_keys(nil, nil)).to be_empty
    end

    it "names one key per layer the legend has something to draw for" do
      entry = MarketData::Domain::VolatilityLayers::Layer.new(step: 1, price: 96.0, atr_distance: 1.0)
      layers = { atr: 4.0, entries: [ entry ], exit: nil }

      expect(helper.chart_layer_keys(layers, indicators)).to eq(%w[levels bollinger rsi])
      expect(helper.chart_layer_keys(layers, nil)).to eq(%w[levels])
      expect(helper.chart_layer_keys(nil, indicators)).to eq(%w[bollinger rsi])
    end
  end

  describe "#chart_anchors_json" do
    def bars(*closes) = closes.map { |close| double(close: close) }

    it "names the line, because the library draws a title only beside its axis label" do
      anchor = JSON.parse(helper.chart_anchors_json(172.4, bars(160.0, 180.0))).first

      expect(anchor["price"]).to eq(172.4)
      expect(anchor["label"]).to eq(I18n.t("market.precio.anclas.costo"))
    end

    it "draws nothing over the price when there is no position to anchor to" do
      expect(helper.chart_anchors_json(nil, bars(160.0, 180.0))).to eq("[]")
    end

    # D107: price lines do not widen the scale, so a cost outside the window
    # lands past the edge of the pane. Absent and stated beats drawn and unseen.
    it "withholds the line when the cost sits outside what the price did here" do
      expect(helper.chart_anchors_json(120.0, bars(160.0, 180.0))).to eq("[]")
      expect(helper.chart_anchors_json(220.0, bars(160.0, 180.0))).to eq("[]")
    end

    it "keeps the line when the cost sits inside the window, edges included" do
      expect(JSON.parse(helper.chart_anchors_json(160.0, bars(160.0, 180.0))).size).to eq(1)
      expect(JSON.parse(helper.chart_anchors_json(180.0, bars(160.0, 180.0))).size).to eq(1)
    end

    # Judged on the closes alone: Bollinger widens the scale when it is on, so
    # reading the visible range would make the line blink with a checkbox.
    it "keeps drawing when there is no series to judge the cost against" do
      expect(JSON.parse(helper.chart_anchors_json(172.4, [])).size).to eq(1)
    end
  end

  describe "#cost_outside_plot?" do
    def bars(*closes) = closes.map { |close| double(close: close) }

    it "answers false when there is nothing to judge" do
      expect(helper.cost_outside_plot?(nil, bars(160.0))).to be(false)
      expect(helper.cost_outside_plot?(172.4, [])).to be(false)
    end

    it "answers on the closes, not on the bands that happen to be drawn" do
      expect(helper.cost_outside_plot?(150.0, bars(160.0, 180.0))).to be(true)
      expect(helper.cost_outside_plot?(170.0, bars(160.0, 180.0))).to be(false)
    end
  end

  describe "#chart_levels_json" do
    def layer(price, distance) = MarketData::Domain::VolatilityLayers::Layer.new(step: 1, price: price, atr_distance: distance)

    it "tells the trailing exit from an entry layer, which its price cannot" do
      levels = helper.chart_levels_json({ atr: 4.0, entries: [ layer(96.0, 1.0) ], exit: layer(88.0, 3.0) }, holding: true)

      expect(JSON.parse(levels)).to eq([
        { "price" => 96.0, "kind" => "entry", "label" => I18n.t("market.layers.etiquetas_plot.entrada", n: 1) },
        { "price" => 88.0, "kind" => "exit", "label" => I18n.t("market.layers.etiquetas_plot.salida") }
      ])
    end

    # D106: the plot takes the short form. The badge butts against the axis
    # price, so four full names covered ~40% of a 318px series -- the recent
    # 40%, which is the part being read. The card two blocks down spells it out.
    it "labels each line with the short form, numbered by its own step" do
      entries = [ MarketData::Domain::VolatilityLayers::Layer.new(step: 1, price: 96.0, atr_distance: 1.0),
                  MarketData::Domain::VolatilityLayers::Layer.new(step: 2, price: 92.0, atr_distance: 2.0) ]

      levels = helper.chart_levels_json({ atr: 4.0, entries: entries, exit: nil }, holding: true)

      expect(JSON.parse(levels).pluck("label")).to eq([
        I18n.t("market.layers.etiquetas_plot.entrada", n: 1),
        I18n.t("market.layers.etiquetas_plot.entrada", n: 2)
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

  # D110: the accent says which SIDE a reading is on, never whether it is good.
  describe "#signal_accent_class and #signal_value" do
    it "accents the two ends and leaves the middle bare" do
      expect(helper.signal_accent_class(state: :overbought)).to include("positive")
      expect(helper.signal_accent_class(state: :oversold)).to include("negative")
      expect(helper.signal_accent_class(state: :neutral)).to be_nil
      expect(helper.signal_accent_class(state: :inside)).to be_nil
    end

    # A state that is above one line and below the other has no single side, so
    # colouring it would have to pick one and be wrong.
    it "leaves a mixed moving-average state unaccented" do
      expect(helper.signal_accent_class(state: :above_50_below_200)).to be_nil
      expect(helper.signal_accent_class(state: :below_50_above_200)).to be_nil
    end

    # ATR carries no side, because no defensible threshold for one exists.
    it "never accents the ATR row" do
      expect(helper.signal_accent_class(state: :rango_diario)).to be_nil
    end

    it "names each figure, since the phrase names them in the other order" do
      value = helper.signal_value(indicator: :moving_average, ma50: 210.56, ma200: 196.52)

      expect(value).to eq("MA50 210.56 · MA200 196.52")
    end

    it "names the bands rather than printing a bare range" do
      value = helper.signal_value(indicator: :bollinger, lower: 208.02, upper: 232.10)

      expect(value).to eq("inferior 208.02 · superior 232.10")
    end

    it "drops the figure a reading could not compute rather than printing a gap" do
      expect(helper.signal_value(indicator: :moving_average, ma50: 210.56, ma200: nil)).to eq("MA50 210.56")
    end

    it "prints the ATR row as a percentage" do
      expect(helper.signal_value(indicator: :atr, value: 3.1415)).to eq("3.1%")
    end
  end
end
