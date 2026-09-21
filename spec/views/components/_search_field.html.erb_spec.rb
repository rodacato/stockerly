require "rails_helper"

RSpec.describe "components/_search_field" do
  it "carries the query it was rendered with" do
    render partial: "components/search_field",
           locals: { placeholder: "Buscar por ID…", value: "timeout" }

    expect(rendered).to include('name="search"')
    expect(rendered).to include('value="timeout"')
    expect(rendered).to include('placeholder="Buscar por ID…"')
  end

  it "puts the magnifier in the card rather than leaving the field bare" do
    render partial: "components/search_field", locals: { placeholder: "Buscar", value: nil }

    expect(rendered).to include("data-icon=\"search\"")
    expect(rendered).to include("bg-transparent")
  end
end
