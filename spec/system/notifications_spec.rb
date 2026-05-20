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
    expect(page).to have_content("Notificaciones")
    expect(page).to have_content("Sin notificaciones por ahora.")
  end

  it "renders grouped notifications with filter chip counts" do
    create(:notification, user: user, notification_type: :alert_triggered, title: "NVDA cruzó USD 600", created_at: 1.hour.ago, read: false)
    create(:notification, user: user, notification_type: :system,          title: "BMV cerrado el lunes", created_at: 1.day.ago, read: true)

    visit notifications_path

    expect(page).to have_content("NVDA cruzó USD 600")
    expect(page).to have_content("BMV cerrado el lunes")
    expect(page).to have_content("Hoy ·")
    expect(page).to have_content("Ayer ·")
    expect(page).to have_content("Mostrando")
  end

  it "marks a single notification as read via the row action" do
    create(:notification, user: user, title: "Sin leer aún", read: false)

    visit notifications_path
    click_button "Marcar leída"

    expect(page).to have_content("Notificación marcada como leída.")
  end

  it "marks all unread as read via the header bulk action" do
    create_list(:notification, 2, user: user, read: false)

    visit notifications_path
    click_button "Marcar todas como leídas"

    expect(page).to have_content("Todas las notificaciones marcadas como leídas.")
    expect(user.notifications.unread.count).to eq(0)
  end

  it "filters by tipo=sistema" do
    create(:notification, user: user, notification_type: :alert_triggered, title: "Una alerta")
    create(:notification, user: user, notification_type: :system,          title: "Un aviso de sistema")

    visit notifications_path(tipo: "sistema")
    expect(page).to have_content("Un aviso de sistema")
  end

  it "shows the empty-filter state when filters return nothing" do
    create(:notification, user: user, notification_type: :alert_triggered, title: "Solo alerta")
    visit notifications_path(tipo: "sistema")
    expect(page).to have_content("Sin coincidencias con tus filtros.")
  end

  it "bulk-deletes read notifications" do
    create_list(:notification, 2, user: user, read: true)
    create(:notification, user: user, read: false)

    visit notifications_path
    click_button "Eliminar leídas"

    expect(page).to have_content("2 notificaciones eliminadas")
    expect(user.notifications.count).to eq(1)
  end
end
