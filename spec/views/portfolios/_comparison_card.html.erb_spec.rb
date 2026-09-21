require "rails_helper"

RSpec.describe "portfolios/_comparison_card" do
  def render_card(points)
    render partial: "portfolios/comparison_card",
           locals: { label: "vs IPC", body: "cuerpo",
                     card: points && { points: BigDecimal(points.to_s) } }
  end

  it "states where the track stops measuring, at both ends" do
    render_card(3)

    expect(rendered).to include(ApplicationController.helpers.signed_points(-10))
    expect(rendered).to include(ApplicationController.helpers.signed_points(10))
  end

  it "draws no bands for the dot to disagree with" do
    render_card(3)

    expect(rendered).not_to include("rounded-full bg-negative")
    expect(rendered).not_to include("rounded-full bg-warning")
    expect(rendered).not_to include("rounded-full bg-positive")
  end

  it "keeps a difference past the clamp on the track" do
    render_card(40)

    expect(rendered).to include("inset-x-[5px]")
    expect(rendered).to include("left: 100.0%")
  end

  it "draws no track when there is nothing to compare" do
    render_card(nil)

    expect(rendered).to include(I18n.t("portfolios.show.sin_comparacion"))
    expect(rendered).not_to include("inset-x-[5px]")
  end
end
