require "rails_helper"

RSpec.describe "Notifications inbox", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "inbox@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "inbox@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "shows the empty-zero state when the user has no notifications" do
    visit notifications_path
    expect(page).to have_content("Bandeja")
    expect(page).to have_content("Bandeja")
    expect(page).to have_content("No hay nada en tu bandeja todavía.")
  end

  it "renders grouped notifications with filter chip counts" do
    # Noon-anchored timestamps so the test doesn't flake when CI runs near
    # midnight UTC (relative offsets like `1.hour.ago` would otherwise spill
    # into the previous calendar day and break the "Hoy ·" / "Ayer ·"
    # bucket assertions below).
    today_noon     = Date.current.beginning_of_day + 12.hours
    yesterday_noon = today_noon - 1.day
    create(:notification, user: user, notification_type: :alert_triggered, title: "NVDA cruzó USD 600", created_at: today_noon, read: false)
    create(:notification, user: user, notification_type: :system,          title: "BMV cerrado el lunes", created_at: yesterday_noon, read: true)

    visit notifications_path

    expect(page).to have_content("NVDA cruzó USD 600")
    expect(page).to have_content("BMV cerrado el lunes")
    expect(page).to have_content("Hoy ·")
    expect(page).to have_content("Ayer ·")
    # Each bucket carries its own count on its chip; "Mostrando X de Y" was
    # the old summary line and the artboard has none.
    expect(page).to have_content("Todas 2")
    expect(page).to have_content("Alertas 1")
  end

  it "marks a single notification as read via the row action" do
    create(:notification, user: user, title: "Sin leer aún", read: false)

    visit notifications_path
    # The row action is a dot, so it is reachable by its accessible name only.
    find("form[action='#{Rails.application.routes.url_helpers.mark_as_read_notification_path(Notification.last)}'] button").click

    expect(page).to have_content("Notificación marcada como leída.")
  end

  it "marks all unread as read via the header bulk action" do
    create_list(:notification, 2, user: user, read: false)

    visit notifications_path
    click_button "Marcar leídas"

    expect(page).to have_content("Todas las notificaciones marcadas como leídas.")
    expect(user.notifications.unread.count).to eq(0)
  end

  it "gives each bucket only its own type, and leaves system notices in Todas" do
    create(:notification, user: user, notification_type: :alert_triggered,   title: "Una alerta")
    create(:notification, user: user, notification_type: :maturity_reminder, title: "CETES por vencer")
    create(:notification, user: user, notification_type: :system,            title: "Un aviso de sistema")

    visit notifications_path(tipo: "cetes")
    expect(page).to have_content("CETES por vencer")
    expect(page).to have_no_content("Una alerta")

    visit notifications_path
    expect(page).to have_content("Un aviso de sistema")
  end

  it "shows the empty-filter state when filters return nothing" do
    create(:notification, user: user, notification_type: :alert_triggered, title: "Solo alerta")
    visit notifications_path(tipo: "cetes")
    expect(page).to have_content("Nada en este filtro. Prueba otro.")
  end

  it "bulk-deletes read notifications" do
    create_list(:notification, 2, user: user, read: true)
    create(:notification, user: user, read: false)

    visit notifications_path
    click_button "Borrar las leídas"

    expect(page).to have_content("2 notificaciones eliminadas")
    expect(user.notifications.count).to eq(1)
  end
end
