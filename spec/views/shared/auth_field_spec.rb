require "rails_helper"

RSpec.describe "shared/_auth_field", type: :view do
  def render_field(**locals)
    render partial: "shared/auth_field", locals: { name: "password", label: "Contraseña" }.merge(locals)
    Capybara.string(rendered)
  end

  it "gives a password input a labelled, unpressed reveal toggle wired to the controller" do
    page = render_field(type: "password")

    expect(page).to have_css("[data-controller='password-visibility'] input[type=password][data-password-visibility-target='input']")
    expect(page).to have_css("button[type=button][aria-pressed='false'][aria-label='Mostrar contraseña'][data-action='password-visibility#toggle']")
  end

  it "adds no toggle to a field that is not a password" do
    page = render_field(type: "email", name: "email")

    expect(page).to have_css("input[type=email]")
    expect(page).not_to have_css("button")
    expect(page).not_to have_css("[data-controller]")
  end
end
