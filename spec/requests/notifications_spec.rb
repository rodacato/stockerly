require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let!(:user) { create(:user, email: "notify@example.com", password: "password123") }

  before do
    login_as(user)
  end

  describe "GET /notifications" do
    it "returns success" do
      get notifications_path
      expect(response).to have_http_status(:ok)
    end

    it "displays notifications" do
      create(:notification, user: user, title: "Alerta NVDA disparada")
      get notifications_path
      expect(response.body).to include("Alerta NVDA disparada")
    end

    it "renders the es-MX header" do
      get notifications_path
      expect(response.body).to include("Notificaciones")
      expect(response.body).to include("Bandeja")
    end

    it "shows the empty state when the user has no notifications" do
      get notifications_path
      expect(response.body).to include("Sin notificaciones por ahora.")
    end

    it "honors the tipo filter and shows the empty-filter state when nothing matches" do
      create(:notification, user: user, notification_type: :alert_triggered, title: "Solo alerta")
      get notifications_path(tipo: "sistema")
      expect(response.body).to include("Sin coincidencias con tus filtros.")
    end

    it "honors the estado filter" do
      create(:notification, user: user, read: true,  title: "Vieja leída")
      create(:notification, user: user, read: false, title: "Nueva sin leer")
      get notifications_path(estado: "no_leidas")
      expect(response.body).to include("Nueva sin leer")
    end
  end

  describe "PATCH /notifications/:id/mark_as_read" do
    let!(:notification) { create(:notification, user: user, title: "Unread Alert", read: false) }

    it "marks notification as read and redirects" do
      patch mark_as_read_notification_path(notification)
      expect(response).to redirect_to(notifications_path)
      expect(notification.reload.read).to be true
    end
  end

  describe "PATCH /notifications/mark_all_read" do
    before do
      create(:notification, user: user, read: false)
      create(:notification, user: user, read: false)
    end

    it "marks all notifications as read" do
      patch mark_all_read_notifications_path
      expect(response).to redirect_to(notifications_path)
      expect(user.notifications.unread.count).to eq(0)
    end
  end

  describe "DELETE /notifications/destroy_read" do
    before do
      create_list(:notification, 2, user: user, read: true)
      create(:notification, user: user, read: false)
    end

    it "deletes only the user's read notifications and flashes the count" do
      expect { delete destroy_read_notifications_path }
        .to change { user.notifications.count }.from(3).to(1)
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to include("2 notificaciones eliminadas")
    end
  end

  describe "authentication guard" do
    it "redirects to login when not authenticated" do
      delete logout_path
      get notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
