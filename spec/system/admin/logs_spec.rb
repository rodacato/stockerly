require "rails_helper"

RSpec.describe "Admin · Bitácora", type: :system do
  before { driven_by :rack_test }

  let!(:admin) do
    create(:user, :admin, :email_verified, email: "admin@stockerly.mx",
                                            password: "password123",
                                            onboarded_at: Time.current,
                                            full_name: "Adrian Romero")
  end
  let!(:admin_portfolio) { create(:portfolio, user: admin) }

  let!(:sync_ok) do
    create(:system_log, severity: :success, module_name: "sync",
           task_name: "SyncPriorityAssetsJob.perform",
           created_at: 5.minutes.ago)
  end
  let!(:auth_login) do
    create(:system_log, severity: :success, module_name: "auth",
           task_name: "Sessions::Create",
           created_at: 1.hour.ago)
  end
  let!(:rate_limit_err) do
    create(:system_log, :error, module_name: "sync",
           task_name: "YahooFinanceImporter.fetch_batch",
           error_message: "HTTP 429 · rate limit excedido tras 3 reintentos.",
           created_at: 30.minutes.ago)
  end
  let!(:warn_row) do
    create(:system_log, :warning, module_name: "queue",
           task_name: "BackgroundQueue.flush",
           error_message: nil,
           created_at: 2.hours.ago)
  end
  let!(:old_one) do
    create(:system_log, severity: :success, module_name: "admin",
           task_name: "VeryOldEvent",
           created_at: 40.days.ago)
  end

  before do
    visit login_path
    fill_in "Correo electrónico", with: admin.email
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders the header band, count chip and CSV export action" do
    visit admin_logs_path

    expect(page).to have_content("Bitácora del sistema")
    expect(page).to have_content("Registros")
    expect(page).to have_content("Eventos, errores y operaciones de los últimos 90 días.")
    expect(page).to have_content("5 registros")
    expect(page).to have_link("Exportar CSV")
  end

  it "lists rows within the default 24h range with module chip and task" do
    visit admin_logs_path

    expect(page).to have_content("SyncPriorityAssetsJob.perform")
    expect(page).to have_content("Sessions::Create")
    expect(page).to have_content("sync")
    expect(page).to have_content("auth")
    # The 40-day-old log is filtered out of the default 24h range
    expect(page).not_to have_content("VeryOldEvent")
  end

  it "filters by severity — error" do
    visit admin_logs_path(severity: "error")

    expect(page).to have_content("YahooFinanceImporter.fetch_batch")
    expect(page).not_to have_content("SyncPriorityAssetsJob.perform")
  end

  it "filters by module" do
    visit admin_logs_path(module_name: "auth")

    expect(page).to have_content("Sessions::Create")
    expect(page).not_to have_content("SyncPriorityAssetsJob.perform")
  end

  it "filters by 7d range to include older entries within that window" do
    visit admin_logs_path(range: "7d")

    expect(page).to have_content("SyncPriorityAssetsJob.perform")
    # 40-day-old still excluded
    expect(page).not_to have_content("VeryOldEvent")
  end

  it "filters by 90d range to surface older entries" do
    visit admin_logs_path(range: "90d")
    expect(page).to have_content("VeryOldEvent")
  end

  it "search hits the error_message text, not just the task name" do
    visit admin_logs_path(search: "rate limit")
    expect(page).to have_content("YahooFinanceImporter.fetch_batch")
  end

  it "renders the empty state when no logs match the filters" do
    visit admin_logs_path(severity: "error", module_name: "auth")

    expect(page).to have_content("Sin registros que coincidan con los filtros.")
    expect(page).to have_link("Limpiar filtros", href: admin_logs_path)
  end

  it "shows the Limpiar filtros affordance when filters are active" do
    visit admin_logs_path(severity: "error")
    expect(page).to have_link("Limpiar filtros", href: admin_logs_path)
  end

  it "renders the warning row's task and module chip" do
    visit admin_logs_path
    expect(page).to have_content("BackgroundQueue.flush")
    expect(page).to have_content("queue")
  end

  it "renders the expandable payload panel for error rows only" do
    visit admin_logs_path

    # Error row carries a toggleable chevron + hidden reveal target
    expect(page.body).to include('data-action="reveal#toggle"')
    expect(page.body).to include('data-reveal-target="content"')
  end

  it "preserves filters in the CSV export link" do
    visit admin_logs_path(severity: "error", module_name: "sync")
    expect(page).to have_link("Exportar CSV",
      href: export_csv_admin_logs_path(severity: "error", module_name: "sync"))
  end

  it "carries severity through the search form via a hidden field" do
    visit admin_logs_path(severity: "error")
    # Regression for #139 — severity is set via segmented links (outside the
    # form), so it must ride along as a hidden field when the search form
    # submits.
    expect(page).to have_field("severity", type: "hidden", with: "error")
  end

  it "escapes user-controlled params in the empty-state filter description" do
    # XSS regression for #139 — the empty-state used to interpolate params
    # into html_safe. Pass a payload and assert it never reaches the DOM as
    # a real element.
    visit admin_logs_path(severity: "error", module_name: "auth", search: "<svg/onload=alert(1)>")
    expect(page).to have_content("Sin registros que coincidan con los filtros.")
    expect(page).not_to have_css("svg[onload]")
  end
end
