require "rails_helper"

RSpec.describe "Admin dashboard (Lumen)", type: :system do
  before { driven_by :rack_test }

  let!(:admin) do
    create(:user, :admin,
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

  it "renders the Lumen header, KPI cards and section titles in es-MX" do
    visit admin_root_path

    expect(page).to have_content("Consola de administración")
    expect(page).to have_content("Panel general")
    expect(page).to have_content("Estado del sistema y operaciones recientes.")

    # KPI eyebrows
    expect(page).to have_content("Activos totales")
    expect(page).to have_content("Sincronizando")
    expect(page).to have_content("Usuarios")
    expect(page).to have_content("Errores 24 h")

    # Section headings
    expect(page).to have_content("Operaciones de sincronización")
    expect(page).to have_content("Últimas 24 horas")
    expect(page).to have_content("Disparar manualmente")
    expect(page).to have_content("Disparar manualmente respeta el rate limit configurado.")
    expect(page).to have_content("Fuentes de datos")
    expect(page).to have_content("Actividad reciente")
  end

  it "shows the healthy-state status pill when no errors and no open circuits" do
    visit admin_root_path
    expect(page).to have_content("Operación nominal · todas las fuentes activas")
    expect(page).to have_content("Sin incidentes en 24 h.")
  end

  it "switches to degraded copy when there are 24h errors" do
    create(:system_log, severity: :error, module_name: "sync",
                        task_name: "SyncPriorityAssetsJob.perform",
                        error_message: "HTTP 429 rate limit",
                        created_at: 10.minutes.ago)

    visit admin_root_path

    expect(page).to have_content("Operación degradada")
    expect(page).to have_content("Último:")
  end

  it "renders recent activity rows with module label and timestamp" do
    create(:system_log, severity: :success, module_name: "sync",
                        task_name: "SyncPriorityAssetsJob.perform",
                        error_message: nil,
                        created_at: 30.minutes.ago)

    visit admin_root_path
    expect(page).to have_content("Sincronización")
    expect(page).to have_content("SyncPriorityAssetsJob.perform")
    expect(page).to have_content("Ver bitácora completa")
  end

  it "renders the empty state when there is no activity" do
    SystemLog.delete_all
    visit admin_root_path
    expect(page).to have_content("Sin actividad en los últimos 20 eventos.")
  end

  it "shows a link to manage integrations" do
    visit admin_root_path
    expect(page).to have_link("Administrar integraciones", href: admin_integrations_path)
  end
end
