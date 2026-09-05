require "rails_helper"

RSpec.describe "Maintenance mode", type: :request do
  after { SiteConfig.set("maintenance_mode", "false") }

  def enable!
    SiteConfig.set("maintenance_mode", "true")
  end

  it "answers 503 rather than the page it was asked for" do
    enable!

    get dashboard_path

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(I18n.t("mantenimiento.titulo"))
  end

  # The three-zone rule: what the user reads is es-MX. This screen was the only
  # user-facing one in the app still written in English.
  it "is written in es-MX, like every other screen a person reads" do
    enable!

    get dashboard_path

    expect(response.body).to include("mantenimiento")
    expect(response.body).not_to include("Under Maintenance", "temporarily unavailable")
  end

  # D1-onb removed the admin framing: on a single-user instance there is no
  # administrator, there is the person whose box this is.
  it "addresses the owner, not an administrator" do
    enable!

    get dashboard_path

    expect(response.body).not_to include("administrator", "administrador")
    expect(response.body).to include(I18n.t("mantenimiento.duenio_enlace"))
  end

  # Negative: the door out has to stay open, or turning the switch on locks the
  # owner out of the screen that turns it off.
  it "leaves login reachable while it is on" do
    enable!

    get login_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("mantenimiento.titulo"))
  end
end
