require "rails_helper"

# The outcome screens hand-rolled their own header and lost the wordmark with
# it — since AU-06 this partial is the only place the auth zone shows the brand.
RSpec.describe "shared/_auth_header" do
  def render_header(**locals)
    render partial: "shared/auth_header", locals: { title: "Revisa tu correo" }.merge(locals)
  end

  it "carries the wordmark the layout no longer holds" do
    render_header

    expect(Capybara.string(rendered)).to have_css("a[href='/'] img[alt='Stockerly']")
  end

  it "keeps carrying it on an outcome screen" do
    render_header(icon: "mark_email_read", tone: :primary)

    expect(Capybara.string(rendered)).to have_css("a[href='/'] img[alt='Stockerly']")
    expect(rendered).to include('data-icon="mark_email_read"')
  end

  it "tones the badge by the outcome it reports" do
    render_header(icon: "link_off", tone: :negative)

    expect(rendered).to include("bg-negative-bg")
    expect(rendered).not_to include("bg-positive-bg")
  end

  it "reads the kicker above the title when the screen has one" do
    render_header(icon: "check_circle", tone: :positive, kicker: "LISTO")

    expect(rendered).to include("LISTO")
    expect(rendered).to include("bg-positive-bg")
  end

  it "draws no badge for a form screen" do
    render_header(subtitle: "Escribe tu correo")

    expect(rendered).to include("Escribe tu correo")
    expect(rendered).not_to include("size-14")
  end
end
