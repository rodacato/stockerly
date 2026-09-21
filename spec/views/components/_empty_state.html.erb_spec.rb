require "rails_helper"

# One geometry served every caller, which is why a section inside a column
# hand-rolled its own card rather than stand ~430px tall in a three-column grid.
RSpec.describe "components/_empty_state" do
  def render_empty(**locals)
    render partial: "components/empty_state",
           locals: { icon: "radar", title: "Nada por aquí", description: nil }.merge(locals)
  end

  it "stands on its own page by default" do
    render_empty

    expect(rendered).to include("py-16")
    expect(rendered).to include("border-dashed")
  end

  it "fits a section when asked for the inline size" do
    render_empty(size: :inline)

    expect(rendered).not_to include("py-16")
    expect(rendered).to include("py-5")
    expect(rendered).to include("border-dashed")
  end

  it "reads as a row at the inline size, not a column" do
    render_empty(size: :inline)

    expect(rendered).not_to include("flex-col")
  end

  it "keeps its call to action at the inline size" do
    render_empty(size: :inline, description: "Carga un movimiento",
                 cta_text: "Importar", cta_path: "/trades/import")

    expect(rendered).to include("Importar")
    expect(rendered).to include("Carga un movimiento")
  end

  it "posts the call to action when the caller says so" do
    render_empty(cta_text: "Buscar", cta_path: "/market/AAPL/fundamentals", cta_method: :post)

    expect(rendered).to include("<form")
    expect(rendered).to include("Buscar")
  end
end
