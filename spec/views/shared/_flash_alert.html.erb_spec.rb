require "rails_helper"

# It took one message, so the two screens that have a list of them each built
# their own box out of the same four classes.
RSpec.describe "shared/_flash_alert" do
  def render_alert(**locals)
    render partial: "shared/flash_alert", locals: locals
  end

  it "says nothing when there is nothing to say" do
    render_alert(message: nil)

    expect(rendered.strip).to be_empty
  end

  it "reads one message as a sentence" do
    render_alert(message: "Correo o contraseña incorrectos")

    expect(rendered).to include("Correo o contraseña incorrectos")
    expect(rendered).not_to include("<li>")
  end

  it "reads several as a list" do
    render_alert(messages: [ "La contraseña es muy corta", "No coincide" ])

    expect(rendered).to include("<li>La contraseña es muy corta</li>")
    expect(rendered).to include("<li>No coincide</li>")
  end

  it "puts a lead above the list when it is given both" do
    render_alert(message: "Corrige lo siguiente", messages: [ "Falta el nombre" ])

    expect(rendered).to include("Corrige lo siguiente")
    expect(rendered).to include("<li>Falta el nombre</li>")
  end

  it "stays quiet for an empty list" do
    render_alert(messages: [])

    expect(rendered.strip).to be_empty
  end
end
