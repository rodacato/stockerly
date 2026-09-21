require "rails_helper"

# One "pick one of N" control. Four copies of it carried no role and no
# aria-selected, and two of those commit through JavaScript rather than a link,
# which is why the primitive has to take both.
RSpec.describe "components/_segmented" do
  def render_segmented(**locals)
    render partial: "components/segmented", locals: { label: "Periodo" }.merge(locals)
  end

  it "commits by navigating when the option carries a url" do
    render_segmented(options: [ [ "1M", "/portfolio?p=1m", true ], [ "1A", "/portfolio?p=1y", false ] ])

    expect(rendered).to include('href="/portfolio?p=1m"')
    expect(rendered).to include('aria-selected="true"')
    expect(rendered).to include('aria-selected="false"')
  end

  it "hands the click to its controller when the option carries attributes instead" do
    render_segmented(options: [ [ "MXN", { data: { choice_target: "option", choice_value: "MXN",
                                                   action: "click->choice#select" } }, true ] ])

    expect(rendered).to include("<button")
    expect(rendered).not_to include("<a ")
    expect(rendered).to include('data-choice-value="MXN"')
    expect(rendered).to include('aria-selected="true"')
  end

  it "announces the group and every option in it, whichever mode it commits in" do
    render_segmented(options: [ [ "Todos", "/admin/logs", true ] ], variant: :chips)

    expect(rendered).to include('role="tablist"')
    expect(rendered).to include('aria-label="Periodo"')
    expect(rendered).to include('role="tab"')
  end

  it "draws the selection off the state it announces, so the two cannot drift" do
    render_segmented(options: [ [ "1M", "/portfolio?p=1m", true ] ])

    expect(rendered).to include("aria-selected:bg-bg-surface")
  end

  it "wraps as chips rather than filling a track when asked" do
    render_segmented(options: [ [ "Todos", "/admin/logs", true ] ], variant: :chips)

    expect(rendered).to include("flex flex-wrap gap-2")
    expect(rendered).not_to include("bg-bg-muted p-1")
  end

  it "keeps the track full-bleed on a phone only" do
    render_segmented(options: [ [ "1M", "/portfolio?p=1m", true ] ])

    expect(rendered).to include("w-full")
    expect(rendered).to include("sm:w-fit")
  end
end
