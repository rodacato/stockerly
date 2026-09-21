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

  it "keeps an extreme reading on the track" do
    render_card(key: :crypto, value: 100)

    expect(rendered).to include("inset-x-[5px]")
    expect(rendered).to include("left: 100.0%")
  end
end
