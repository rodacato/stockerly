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
      create(:notification, user: user, title: "Test Alert Fired")
      get notifications_path
      expect(response.body).to include("Test Alert Fired")
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

  describe "POST /notifications/mark_all_read" do
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

  describe "authentication guard" do
    it "redirects to login when not authenticated" do
      delete logout_path
      get notifications_path
      expect(response).to redirect_to(login_path)
    end
  end
end
