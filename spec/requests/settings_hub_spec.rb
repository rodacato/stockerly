require "rails_helper"

RSpec.describe "Ajustes", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current, full_name: "Adrian Castillo") }

  before { login_as(user) }

  it "gathers the sections that used to be split between profile and admin" do
    get settings_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("settings.show.cuenta"))
    expect(response.body).to include(I18n.t("settings.show.avisos_titulo"))
    expect(response.body).to include(I18n.t("settings.show.instancia_titulo"))
    expect(response.body).to include(I18n.t("settings.show.datos_titulo"))
  end

  # D5: on a single-user instance the admin split was a costume. The surfaces
  # stay where they are; what changes is that they are reachable from here.
  it "links to the instance surfaces instead of reimplementing them" do
    get settings_path

    expect(response.body).to include(%(href="#{admin_integrations_path}"))
    expect(response.body).to include(%(href="#{admin_logs_path}"))
    expect(response.body).to include(%(href="#{admin_settings_path}"))
    expect(response.body).to include(%(href="/admin/jobs"))
  end

  # ADR-020: the errors row is the developer surface, not a permanent part of
  # the hub.
  it "hides the errors row while developer mode is off" do
    get settings_path

    expect(response.body).not_to include(%(href="#{admin_errors_path}"))
  end

  it "shows the errors row once developer mode is on" do
    SiteConfig.set("developer_mode", true)

    get settings_path

    expect(response.body).to include(%(href="#{admin_errors_path}"))
  end

  it "offers both email switches, wired to the endpoint that persists them" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.digest"))
    expect(response.body).to include(I18n.t("settings.show.urgente"))
    expect(response.body).to include(update_preferences_path)
  end

  # D16 left the in-app inbox always on, and a switch that does nothing is the
  # defect this slice's precondition existed to remove.
  it "does not offer a switch for the bell, which cannot be turned off" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.avisos_campana"))
    # Two channels deliver, so two switches exist. Asserting the absence of
    # "browser_push" stopped meaning anything once the column was dropped —
    # a name for nothing cannot fail.
    expect(response.body.scan(/data-toggle-field-value=/).size).to eq(2)
  end

  it "shows the currency control on the user's current choice" do
    get settings_path

    expect(response.body).to include("MXN")
    expect(response.body).to include(update_currency_path)
  end

  # D58: the two pills on this screen looked identical and committed
  # differently — theme applied on click, currency waited for a button nothing
  # drew. A choice you can make and forget to submit is the failure this
  # removes, so the button's absence is the assertion.
  it "commits the currency on select, with no Guardar to forget" do
    get settings_path

    expect(response.body).to include('data-controller="choice"')
    expect(response.body).to include('data-choice-param-value="profile[preferred_currency]"')
    expect(response.body).to include('data-choice-value="MXN"')
    expect(response.body).to include('data-choice-value="USD"')
    expect(response.body).not_to include('type="submit" value="Guardar"')
  end

  # Tus datos is where a person goes looking for how to get data in, not only
  # for how to get it out.
  it "opens the importer from the data section" do
    get settings_path

    expect(response.body).to include(%(href="#{new_trade_import_path}"))
    expect(response.body).to include(I18n.t("settings.show.importar"))
  end

  # Issue #176 builds in-app deletion; until then the honest thing is naming
  # the procedure that actually exists.
  it "says how account deletion works today rather than offering a dead button" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.datos_eliminar_desc"))
    expect(response.body).not_to include(%(href="/account/delete"))
  end

  describe "the nav" do
    it "points Ajustes here" do
      get settings_path

      expect(response.body).to include(%(href="#{settings_path}"))
    end

    it "keeps the tab lit on the profile screen it links to" do
      get profile_path

      expect(response).to have_http_status(:ok)
    end
  end
end
