require "rails_helper"

RSpec.describe "components/_definition_list" do
  it "pairs each label with its value" do
    render partial: "components/definition_list",
           locals: { rows: [ [ "Ruby", "4.0.6" ], [ "Rails", "8.1.3" ] ] }

    expect(rendered).to include("<dt")
    expect(rendered).to include("Ruby")
    expect(rendered).to include("4.0.6")
    expect(rendered).to include("Rails")
  end

  it "divides the rows rather than boxing each one" do
    render partial: "components/definition_list", locals: { rows: [ [ "Ruby", "4.0.6" ] ] }

    expect(rendered).to include("divide-y divide-border-default")
    expect(rendered.scan("<dl").size).to eq(1)
  end

  # A row whose reading means something is wrong must not be the same grey as
  # the facts around it; a row without a tone keeps the default treatment.
  it "marks a row asked for the warning tone, and only that row" do
    render partial: "components/definition_list",
           locals: { rows: [ [ "Ruby", "4.0.6" ], [ "Errores", "400", :warning ] ] }

    expect(rendered.scan("text-warning-fg").size).to eq(1)
    expect(rendered).to match(/400<\/dd>/)
  end

  it "leaves an untoned row on the default treatment" do
    render partial: "components/definition_list", locals: { rows: [ [ "Ruby", "4.0.6" ] ] }

    expect(rendered).to include("text-fg-default")
    expect(rendered).not_to include("text-warning-fg")
  end

  it "renders an empty list rather than failing on one" do
    render partial: "components/definition_list", locals: { rows: [] }

    expect(rendered).to include("<dl")
    expect(rendered).not_to include("<dt")
  end
end
