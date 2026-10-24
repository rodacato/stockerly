require "rails_helper"

# The card used to draw three equal bands under a dot that is not on their
# scale — a reader who takes the bands literally reads the wrong verdict.
RSpec.describe "dashboard/_sentiment_card" do
  def render_card(key:, value:, label_key: :neutral, delta: nil)
    render partial: "dashboard/sentiment_card",
           locals: { card: Trading::UseCases::AssemblePanorama::SentimentCard.new(
             key: key, value: value, label_key: label_key, delta: delta
           ) }
  end

  it "names both ends of the crypto scale" do
    render_card(key: :crypto, value: 62)

    expect(rendered).to include(I18n.t("comun.clasificacion.extreme_fear"))
    expect(rendered).to include(I18n.t("comun.clasificacion.extreme_greed"))
  end

  it "names both ends of the watchlist scale in its own vocabulary" do
    render_card(key: :watchlist, value: 40)

    expect(rendered).to include(I18n.t("comun.clasificacion.very_bearish"))
    expect(rendered).to include(I18n.t("comun.clasificacion.very_bullish"))
  end

  it "draws no bands for the dot to disagree with" do
    render_card(key: :crypto, value: 62)

    expect(rendered).not_to include("rounded-full bg-negative")
    expect(rendered).not_to include("rounded-full bg-warning")
    expect(rendered).not_to include("rounded-full bg-positive")
  end

  # D175: colour by the classification, never by a band the dot could miss.
  it "colours the reading by its label, fear on the left and greed on the right" do
    render_card(key: :crypto, value: 20, label_key: :extreme_fear)

    expect(rendered).to include("size-2 shrink-0 rounded-full bg-sentiment-1")
    expect(rendered).to include("from-sentiment-1 via-sentiment-3 to-sentiment-5")
  end

  it "runs the volatility scale from calm to high, so calm reads at the green end" do
    render_card(key: :volatility, value: 12, label_key: :calm)

    expect(rendered).to include("rounded-full bg-sentiment-5")
    expect(rendered).to include("from-sentiment-5 via-sentiment-3 to-sentiment-1")
  end

  it "leaves a classification it does not know uncoloured" do
    render_card(key: :watchlist, value: 50, label_key: :sideways)

    expect(rendered).to include("rounded-full bg-fg-subtle")
    expect(rendered).not_to match(/rounded-full bg-sentiment-\d/)
  end

  it "keeps an extreme reading on the track" do
    render_card(key: :crypto, value: 100)

    expect(rendered).to include("inset-x-[5px]")
    expect(rendered).to include("left: 100.0%")
  end
end
