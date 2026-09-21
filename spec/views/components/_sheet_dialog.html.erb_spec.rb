require "rails_helper"

RSpec.describe "components/_sheet_dialog" do
  def render_sheet
    render partial: "components/sheet_dialog",
           locals: { frame_id: "trade_sheet", url: "/trades/new", label: "Registrar" }
  end

  it "opens the route in the frame it mounts" do
    render_sheet

    expect(rendered).to include('data-turbo-frame="trade_sheet"')
    expect(rendered).to include('id="trade_sheet"')
  end

  # D49's rule: a full-bleed control is full-bleed on a phone only.
  it "reads the same width rule the segmented control does" do
    render_sheet
    trigger = rendered.dup
    render partial: "components/segmented", locals: { label: "Pestañas", options: [ [ "Una", "/", true ] ] }

    expect(trigger).to include("w-full")
    expect(trigger).to include("sm:w-fit")
    expect(rendered).to include("w-full")
    expect(rendered).to include("sm:w-fit")
  end
end
