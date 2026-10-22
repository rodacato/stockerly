require "rails_helper"

# ADR-031 §2: the assistant reads only through this registry, and every read
# either brings cards or says why it could not.
RSpec.describe Assistant::Capabilities::Registry do
  subject(:registry) { described_class.new }

  let!(:asset) { create(:asset, symbol: "NVDA", name: "NVIDIA", current_price: 110, price_updated_at: Time.current) }

  before do
    create(:technical_reading, asset: asset, readings: { "close" => 110.0, "rsi" => 72.4, "sma_50" => 105.0, "sma_200" => 90.0 })
  end

  it "refuses a name it does not list, whoever asks" do
    result = registry.call("portfolio.positions", symbol: "NVDA")

    expect(result).not_to be_ok
    expect(result.reason).to eq(:unknown)
  end

  it "refuses input the capability does not declare" do
    expect(registry.call("asset.quote").reason).to eq(:invalid_input)
    expect(registry.call("asset.quote", symbol: "NVDA", sql: "select 1").reason).to eq(:invalid_input)
  end

  it "says there is no data for an unknown symbol rather than answering empty" do
    result = registry.call("asset.quote", symbol: "NOPE")

    expect(result.reason).to eq(:no_data)
    expect(result.cards).to eq([])
  end

  # The supplier is another context's read API: the one seam stubbed here.
  it "turns a failing supplier into a failure, not an exception or an empty success" do
    allow(MarketData::Queries::AssetBrief).to receive(:call).and_raise(ActiveRecord::StatementInvalid, "boom")

    expect(registry.call("asset.indicators", symbol: "NVDA").reason).to eq(:error)
  end

  it "reads the whole technical reading when no indicator is named" do
    titles = registry.call("asset.indicators", symbol: "NVDA").cards.map(&:title)

    expect(titles).to include("RSI (14) · NVDA", "#{I18n.t("market.glosario.moving_average.nombre")} · NVDA")
  end

  it "narrows the reading to the indicators asked for" do
    cards = registry.call("asset.indicators", symbol: "NVDA", only: %w[rsi]).cards

    expect(cards.map(&:figure)).to eq([ "72.4" ])
  end

  it "keeps a card within its capability's budget" do
    long = "palabra " * 200
    card = Assistant::Domain::Card.new(kind: "glossary", title: "X", body: long, figure: nil, source: nil)

    expect(card.within(Assistant::Capabilities::Capability::MAX_CHARS).body.length).to be <= Assistant::Capabilities::Capability::MAX_CHARS
  end

  it "reads each asset once per question, however many capabilities ask" do
    allow(MarketData::Queries::AssetBrief).to receive(:call).and_call_original

    registry.call("asset.quote", symbol: "NVDA")
    registry.call("asset.indicators", symbol: "nvda")

    expect(MarketData::Queries::AssetBrief).to have_received(:call).once
  end
  describe "market context" do
    it "reads the indices and a fresh crypto sentiment, each card with its date" do
      create(:market_index, symbol: "IPC", name: "IPC Mexico", value: 54_000, change_percent: 0.6, is_open: false)
      create(:fear_greed_reading, :extreme_fear)

      cards = registry.call("market.pulse").cards

      expect(cards.first.body).to eq("IPC Mexico 54,000.00 +0.6% (cerrado)")
      expect(cards.last).to have_attributes(figure: "15", body: "Miedo extremo")
      expect(cards.map(&:source)).to all(include(I18n.l(Date.current, format: :long)))
    end

    it "prints the IPC's proxy by its day change alone, never a level it does not have" do
      create(:market_index, symbol: "IPC", name: "NAFTRAC · sigue al IPC", value: nil, change_percent: 0.4, is_open: true)

      expect(registry.call("market.pulse").cards.first.body).to eq("NAFTRAC · sigue al IPC +0.4% (abierto)")
    end

    it "says there is no market data rather than serving a stale reading" do
      create(:fear_greed_reading, :stale)

      expect(registry.call("market.pulse").reason).to eq(:no_data)
    end

    it "reads USD/MXN on a date, naming the day the rate is for" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 1), rate: 17.1234, source: "Banxico/SF43718")

      card = registry.call("fx.rate", date: "2026-05-03").cards.sole

      expect(card).to have_attributes(figure: "17.1234", source: "Banxico",
                                      body: "vigente el #{I18n.l(Date.new(2026, 5, 1), format: :long)}")
    end

    it "reads no rate for a future or malformed date" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: Date.current, rate: 18.2, source: "Banxico/SF43718")

      expect(registry.call("fx.rate").cards.sole.figure).to eq("18.2000")
      expect(registry.call("fx.rate", date: (Date.current + 1).iso8601).reason).to eq(:no_data)
      expect(registry.call("fx.rate", date: "el 3 de mayo").reason).to eq(:no_data)
    end

    it "reads the CETES curve term by term" do
      CetesRateHistory.record(term: "28", date: Date.new(2026, 10, 15), rate: 7.25)

      expect(registry.call("cetes.curve").cards.sole.body).to eq("28 días 7.25% (#{I18n.l(Date.new(2026, 10, 15), format: :long)})")
    end

    it "reads the next report and the last surprise of an asset" do
      create(:earnings_event, asset: asset, report_date: Date.current + 30, timing: :after_market_close)
      create(:earnings_event, asset: asset, report_date: Date.current - 60, estimated_eps: 0.64, actual_eps: 0.68)

      body = registry.call("asset.earnings", symbol: "NVDA").cards.sole.body

      expect(body).to include("después del cierre", "UPA 0.68 contra 0.64 estimada")
    end

    it "has no earnings card for an asset with no dates" do
      expect(registry.call("asset.earnings", symbol: "NVDA").reason).to eq(:no_data)
    end
  end

  # ADR-031's 2026-10-22 amendment: the owner's holdings, only behind the switch.
  describe "the owner's holdings" do
    let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
    let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
      position = create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100, status: :open)
      create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy, shares: 10, price_per_share: 100,
                     currency: "USD", fx_rate_at_execution: 17.0, executed_at: 30.days.ago)
      asset.update!(currency: "USD", current_price: 120)
    end

    it "does not list them while the switch is off" do
      expect(registry.call("portfolio.positions").reason).to eq(:unknown)
      expect(registry.call("portfolio.events").reason).to eq(:unknown)
    end

    context "with the switch on" do
      subject(:registry) { described_class.new(holdings: true) }

      it "states the portfolio as Activos does, in the owner's currency" do
        total, list = registry.call("portfolio.positions").cards

        expect(total.figure).to eq("MXN 24,000.00")
        expect(total.body).to include("Costo MXN 17,000.00", "Ganancia +MXN 7,000.00 (+41.2%)", "1 posición abierta")
        expect(list.body).to eq("NVDA MXN 24,000.00 (100.0%) +41.2%")
      end

      it "states one position with what the asset and the exchange rate each did" do
        card = registry.call("portfolio.positions", symbol: "NVDA").cards.sole

        expect(card.title).to eq("Tu posición en NVIDIA")
        expect(card.body).to include("10 títulos", "Por el activo +MXN 4,000.00", "Por el tipo de cambio +MXN 3,000.00")
      end

      it "says there is no data for a symbol the owner does not hold" do
        expect(registry.call("portfolio.positions", symbol: "AMZN").reason).to eq(:no_data)
      end

      it "names what is coming for the holdings, by date" do
        create(:earnings_event, asset: asset, report_date: 3.days.from_now.to_date)

        card = registry.call("portfolio.events").cards.sole

        expect(card.body).to eq("NVDA reporta resultados el #{I18n.l(3.days.from_now.to_date, format: :long)} (en 3 días)")
      end
    end
  end
end
