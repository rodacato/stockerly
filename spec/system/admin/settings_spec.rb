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

  it "renders the header and card titles in es-MX" do
    visit admin_settings_path

    expect(page).to have_content("Configuración")
    expect(page).to have_content("Ajustes del sistema")
    expect(page).to have_content("Toggles globales que afectan toda la aplicación. Cambios surten efecto inmediato.")
    expect(page).to have_content("Acceso a la plataforma")
    expect(page).to have_content("Datos y sincronización")
    expect(page).to have_content("Diagnóstico")
    expect(page).to have_content("Cambios recientes de configuración")
  end

  it "labels the toggles in es-MX" do
    visit admin_settings_path

    expect(page).to have_content("Registro abierto")
    expect(page).to have_content("Modo mantenimiento")
    expect(page).to have_content("Sincronización automática")
    expect(page).to have_content("Notificaciones por correo")
  end

  it "does not show the maintenance callout when maintenance is OFF" do
    SiteConfig.set("maintenance_mode", false)
    visit admin_settings_path
    expect(page).not_to have_content("Banner activo")
  end

  it "shows the maintenance warning callout when maintenance is ON" do
    SiteConfig.set("maintenance_mode", true)
    visit admin_settings_path

    expect(page).to have_content("Banner activo")
    expect(page).to have_content("Stockerly está en mantenimiento. Volvemos pronto.")
  end

  it "renders runtime diagnostic values (mono labels)" do
    visit admin_settings_path

    expect(page).to have_content("Versión")
    expect(page).to have_content("Ambiente")
    expect(page).to have_content("Ruby")
    expect(page).to have_content("Rails")
    expect(page).to have_content("Solid Queue")
    expect(page).to have_content(RUBY_VERSION)
    expect(page).to have_content(Rails.version)
  end

  it "persists toggle changes and writes an audit entry" do
    SiteConfig.set("registration_open", false)

    expect {
      page.driver.submit :patch, admin_settings_path,
                         { "registration_open" => "1", "maintenance_mode" => "0",
                           "auto_sync_enabled" => "0", "email_notifications_enabled" => "0" }
    }.to change(SiteConfigChange, :count).by(1)

    expect(SiteConfig.registration_open?).to be true
    visit admin_settings_path
    expect(page).to have_content("adrian cambió")
    expect(page).to have_content("registro_abierto")
  end

  it "renders the empty audit message when no changes are recorded" do
    visit admin_settings_path
    expect(page).to have_content("Aún no hay cambios registrados.")
  end

  it "fetches the four toggle rows with a batched SELECT (regression: N+1)" do
    %w[registration_open maintenance_mode auto_sync_enabled email_notifications_enabled].each do |key|
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

    # The controller batches all 4 toggle keys into a single WHERE-IN.
    batched = queries.count { |q| q.match?(/IN \(.+,.+,.+,.+\)/) }
    expect(batched).to be >= 1
  end

  it "rolls the SiteConfig + SiteConfigChange writes back together on failure" do
    SiteConfig.set("registration_open", false)
    allow(SiteConfigChange).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect {
      begin
        page.driver.submit :patch, admin_settings_path,
                           { "registration_open" => "1", "maintenance_mode" => "0",
                             "auto_sync_enabled" => "0", "email_notifications_enabled" => "0" }
      rescue ActiveRecord::RecordInvalid
        # Expected — the transaction should re-raise.
      end
    }.not_to change { SiteConfig.registration_open? }
  end
end
