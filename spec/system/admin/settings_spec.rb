require "rails_helper"

RSpec.describe "Admin settings (Lumen)", type: :system do
  before { driven_by :rack_test }

  let!(:admin) do
    create(:user, :admin, full_name: "Adrian Cancino",
           email: "admin@test.com", password: "password123",
           onboarded_at: Time.current, email_verified_at: Time.current)
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

    expect(page).to have_content("La app está bloqueada y muestra un banner.")
  end

  it "links to the Mission Control jobs dashboard from Diagnóstico" do
    visit admin_settings_path

    expect(page).to have_link("Abrir Mission Control", href: "/admin/jobs")
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
    expect(page).to have_content("modo_mantenimiento")
    expect(page).to have_no_content("adrian cambió")
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
    }.not_to change { SiteConfig.maintenance_mode? }
  end
end
