require "rails_helper"

RSpec.describe "portfolios/_comparison_card" do
  def render_card(points)
    render partial: "portfolios/comparison_card",
           locals: { label: "vs IPC", body: "cuerpo", level_label: "Igual que el IPC",
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

  describe "the standing chip" do
    it "reads ahead in green when the points are positive" do
      render_card(1.5)

      expect(rendered).to include("vas arriba", "bg-positive-bg")
      expect(rendered).not_to include("Igual que el IPC")
    end

    it "reads behind in red when the points are negative" do
      render_card(-1.5)

      expect(rendered).to include("vas abajo", "bg-negative-bg")
    end

    it "reads level and neutral on an exact tie, never ahead" do
      render_card(0)

      expect(rendered).to include("Igual que el IPC", "bg-bg-muted")
      expect(rendered).not_to include("vas arriba")
      expect(rendered).not_to include("bg-positive-bg")
    end

    it "treats a difference that rounds to 0.0 as a tie" do
      render_card(0.03)

      expect(rendered).to include("Igual que el IPC")
      expect(rendered).to include("0.0 pts")
      expect(rendered).not_to include("vas arriba")
    end
  end
end
