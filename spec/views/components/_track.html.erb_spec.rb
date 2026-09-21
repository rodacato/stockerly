require "rails_helper"

# The primitive D96 drew for the 52-week range. Its two jobs are the ones the
# hand-rolled copies got wrong: an end the reader can name, and a marker that
# stays on the track at either extreme.
RSpec.describe "components/_track" do
  def render_track(**locals)
    render partial: "components/track",
           locals: { position: 50, low_label: "bajo", high_label: "alto" }.merge(locals)
  end

  it "names both ends of the scale" do
    render_track

    expect(rendered).to include("bajo")
    expect(rendered).to include("alto")
  end

  it "draws one neutral track rather than bands a value could disagree with" do
    render_track

    expect(rendered).not_to include("bg-negative")
    expect(rendered).not_to include("bg-warning")
    expect(rendered).not_to include("bg-positive")
  end

  it "insets the markers by their own half-width so neither end overhangs" do
    render_track(position: 100, marker: 0)

    expect(rendered).to include("inset-x-[5px]")
  end

  it "clamps a position outside the scale onto it" do
    render_track(position: 140)

    expect(rendered).to include("left: 100.0%")
    expect(rendered).not_to include("left: 140")
  end

  it "keeps the second marker on the same scale as the value" do
    render_track(position: 30, marker: 30)

    expect(rendered.scan("left: 30.0%").size).to eq(2)
  end

  it "holds the marker label away from the edge, where the value may sit" do
    render_track(position: 0, marker: 0, marker_label: "tu costo")

    expect(rendered).to include("tu costo")
    expect(rendered).to include("left: 6.0%")
  end

  it "draws no marker row when the caller has no second value" do
    render_track

    expect(rendered).not_to include("bg-primary")
  end
end
