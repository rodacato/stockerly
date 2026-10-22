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
end
