require "rails_helper"

RSpec.describe "Admin settings (Lumen)", type: :system do
  before { driven_by :rack_test }

  let!(:admin) do
    create(:user, :admin, full_name: "Adrian Cancino",
           email: "admin@test.com", password: "password123",
           onboarded_at: Time.current)
  end
  let!(:portfolio) { create(:portfolio, user: admin) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "admin@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "puts the diagnosis first, then what you can change about it" do
    visit admin_settings_path

    expect(page).to have_content("Estado y mantenimiento")
    expect(page).to have_content("Diagnóstico")
    expect(page).to have_content("Interruptores de la instancia")
    expect(page).to have_content("Cambios recientes")
  end

  it "labels the three switches in es-MX" do
    visit admin_settings_path

    expect(page).to have_content("Modo mantenimiento")
    expect(page).to have_content("Sincronización automática")
    expect(page).to have_content("Envío de correo")
  end

  it "has no Guardar button — each switch is its own PATCH" do
    visit admin_settings_path
    expect(page).to have_no_button("Guardar ajustes")
  end

  it "does not show the maintenance callout when maintenance is OFF" do
    SiteConfig.set("maintenance_mode", false)
    visit admin_settings_path
    expect(page).to have_no_content("La app está bloqueada")
  end

  it "shows the maintenance warning callout when maintenance is ON" do
    SiteConfig.set("maintenance_mode", true)
    visit admin_settings_path

    expect(page).to have_content("Quien no haya iniciado sesión ve la página de mantenimiento.")
  end

  # The switch used to promise a banner. The owner is exempt and everyone else
  # gets the 503 page; no banner is rendered anywhere.
  it "describes maintenance by what it does, not by a banner that does not exist" do
    SiteConfig.set("maintenance_mode", true)
    visit admin_settings_path

    expect(page).to have_no_content("banner")
  end

  # D5 gave Ajustes one hub, and it already carries rows for Trabajos and for
  # the error tracker. Diagnóstico offering them a second time was the admin
  # split growing back a door at a time.
  it "does not offer a second way into the surfaces the Ajustes hub already opens" do
    visit admin_settings_path

    expect(page).to have_no_link(href: "/admin/jobs")
    expect(page).to have_no_link(href: admin_errors_path)
  end

  it "renders runtime diagnostic values (mono labels)" do
    visit admin_settings_path

    expect(page).to have_content("Versión")
    expect(page).to have_content("Entorno")
    expect(page).to have_content("Ruby")
    expect(page).to have_content("Rails")
    expect(page).to have_content("Trabajos")
    expect(page).to have_content(RUBY_VERSION)
    expect(page).to have_content(Rails.version)
  end

  it "persists toggle changes and writes an audit entry" do
    SiteConfig.set("maintenance_mode", false)

    expect {
      page.driver.submit :patch, admin_settings_path,
                         { "maintenance_mode" => "1",
                           "auto_sync_enabled" => "0", "email_notifications_enabled" => "0" }
    }.to change(SiteConfigChange, :count).by(1)

    expect(SiteConfig.maintenance_mode?).to be true
    visit admin_settings_path
    # D5: one account, so naming who flipped it is a costume. The artboard
    # shows what changed and when, and SiteConfigChange still records the actor.
    expect(page).to have_content("Modo mantenimiento · desactivado → activado")
    expect(page).to have_no_content("modo_mantenimiento")
    expect(page).to have_no_content("adrian cambió")
  end

  it "names the developer switch in the audit trail like the other three" do
    create(:site_config_change, admin: admin, key: "developer_mode", old_value: "false", new_value: "true")
    visit admin_settings_path

    expect(page).to have_content("Modo desarrollador · desactivado → activado")
  end

  # Nothing writes a SystemLog under the admin module, so the link opened an
  # empty list every time.
  it "does not link to a Registros filter that is always empty" do
    create(:site_config_change, admin: admin, key: "maintenance_mode", old_value: "false", new_value: "true")
    visit admin_settings_path

    expect(page).to have_no_link(href: admin_logs_path(module_name: "admin"))
  end

  it "renders the empty audit message when no changes are recorded" do
    visit admin_settings_path
    expect(page).to have_content("Todavía no hay cambios registrados.")
  end

  it "fetches the three toggle rows with a batched SELECT (regression: N+1)" do
    %w[maintenance_mode auto_sync_enabled email_notifications_enabled].each do |key|
      SiteConfig.set(key, true)
    end

    queries = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_n, _s, _f, _id, payload|
      sql = payload[:sql]
      next if payload[:name] == "SCHEMA"
      next if QueryCounter::IGNORE.match?(sql)
      queries << sql if sql.include?("site_configs")
    end

    visit admin_settings_path
    ActiveSupport::Notifications.unsubscribe(sub)

    # The controller batches all 3 toggle keys into a single WHERE-IN.
    batched = queries.count { |q| q.match?(/IN \(.+,.+,.+\)/) }
    expect(batched).to be >= 1
  end

  it "rolls the SiteConfig + SiteConfigChange writes back together on failure" do
    SiteConfig.set("maintenance_mode", false)
    allow(SiteConfigChange).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect {
      begin
        page.driver.submit :patch, admin_settings_path,
                           { "maintenance_mode" => "1",
                             "auto_sync_enabled" => "0", "email_notifications_enabled" => "0" }
      rescue ActiveRecord::RecordInvalid
        # Expected — the transaction should re-raise.
      end
    }.not_to(change { SiteConfig.maintenance_mode? })
  end
end
