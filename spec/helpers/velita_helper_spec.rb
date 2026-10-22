require "rails_helper"

# A suggestion is a promise: tapping it must bring the card it names, or the
# drawer opens on an answer with nothing to stand on (D166, ADR-031 §2).
RSpec.describe VelitaHelper, type: :helper do
  def kinds(question, symbol: nil) = Assistant::Domain::ContextSelector.call(question: question, symbol: symbol).map { |card| [ card.kind, card.title ] }

  it "keeps every Hoy suggestion answerable from the glossary" do
    expected = [ "Contra CETES", "CETES a 28 días", I18n.t("dashboard.ayuda.earnings.titulo") ]

    helper.assistant_suggestions(from: "panorama", symbol: nil, seen: %w[vs_cetes earnings]).zip(expected).each do |suggestion, title|
      expect(kinds(suggestion)).to include([ "glossary", title ]), "«#{suggestion}» did not retrieve «#{title}»"
    end
  end

  describe "on an asset's page" do
    let!(:asset) { create(:asset, symbol: "NVDA", name: "NVIDIA", current_price: 110, price_updated_at: Time.current) }

    before do
      create(:asset_fundamental, asset: asset, metrics: { "fifty_two_week_low" => "90.5", "fifty_two_week_high" => "130.25" })
      create(:technical_reading, asset: asset, readings: { "close" => 110.0, "rsi" => 72.4 })
      create(:news_article, related_ticker: "NVDA", title: "Nvidia reporta", published_at: 1.hour.ago)
    end

    it "brings the card each suggestion names" do
      rsi, range, headlines = helper.assistant_suggestions(from: "activos", symbol: "NVDA")

      expect(kinds(rsi, symbol: "NVDA").map(&:first)).to eq(%w[glossary reading])
      expect(kinds(range, symbol: "NVDA").map(&:first)).to eq(%w[range])
      expect(kinds(headlines, symbol: "NVDA").map(&:first)).to eq(%w[headlines])
    end
  end

  it "suggests nothing on a screen with no drawn suggestions" do
    expect(helper.assistant_suggestions(from: "reglas", symbol: nil)).to be_empty
  end
end
