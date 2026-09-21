require "rails_helper"

# The shape and its colour both come from the closes the caller passes, so the
# no-series case is the one that used to invent both.
RSpec.describe "components/_sparkline" do
  def render_sparkline(heights)
    render partial: "components/sparkline", locals: { heights: heights }
  end

  it "draws no line when there is no series to draw" do
    render_sparkline(nil)

    expect(rendered).not_to include("<polyline")
  end

  it "keeps its box when it has nothing to draw, so no row reflows" do
    render_sparkline(nil)

    expect(rendered).to include("h-8 w-16")
  end

  it "draws a week that did not move neutral, since it did not rise" do
    render_sparkline([ 50, 50, 50 ])

    expect(rendered).to include("stroke-border-strong")
  end

  it "draws a rising week positive" do
    render_sparkline([ 0, 40, 100 ])

    expect(rendered).to include("stroke-positive")
  end

  it "draws a falling week negative" do
    render_sparkline([ 100, 40, 0 ])

    expect(rendered).to include("stroke-negative")
  end
end
