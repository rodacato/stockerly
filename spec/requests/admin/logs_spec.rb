require "rails_helper"

RSpec.describe "Admin logs error details", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  before { login_as(admin) }

  describe "GET /admin/logs" do
    it "renders error_message content for error logs" do
      create(:system_log, :error, task_name: "Price Sync Failed",
             error_message: "Connection timeout after 5000ms")
      get admin_logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Connection timeout after 5000ms")
    end

    it "renders expand button for logs with error details" do
      create(:system_log, :error, error_message: "Gateway timeout")
      get admin_logs_path

      expect(response.body).to include("expand_more")
      expect(response.body).to include('data-action="reveal#toggle"')
    end

    it "does not render expand button for success logs" do
      create(:system_log, task_name: "Successful Sync", severity: :success)
      get admin_logs_path

      expect(response.body).not_to include("expand_more")
      expect(response.body).not_to include('data-action="reveal#toggle"')
    end

    it "renders the error detail row as hidden with reveal target" do
      create(:system_log, :error, error_message: "Rate limit exceeded")
      get admin_logs_path

      expect(response.body).to include('data-reveal-target="content"')
      expect(response.body).to include('data-controller="reveal"')
    end
  end
end
