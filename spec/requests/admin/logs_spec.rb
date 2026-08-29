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

    it "renders an expand control (chevron) for logs with error details" do
      create(:system_log, :error, error_message: "Gateway timeout")
      get admin_logs_path

      # Every row renders a chevron column; rows with error_message wire the
      # toggle action onto the icon.
      expect(response.body).to include('data-action="reveal#toggle"')
      expect(response.body).to include("expand_more")
    end

    it "does not wire the toggle action for success logs" do
      create(:system_log, task_name: "Successful Sync", severity: :success)
      get admin_logs_path

      # The chevron icon still renders (placeholder), but no toggle action
      # nor reveal-target panel exists for success rows.
      expect(response.body).not_to include('data-action="reveal#toggle"')
      expect(response.body).not_to include('data-reveal-target="content"')
    end

    # Every sync job writes its outcome into the column named error_message,
    # success included. The screen painted that column red by name, so a
    # healthy sync read as a failure. The one success example above never
    # caught it because it creates a log with no message at all.
    it "does not paint a successful sync's message as an error" do
      create(:system_log, task_name: "Market Indices Sync", severity: :success,
             error_message: "6 indices updated")
      get admin_logs_path

      expect(response.body).to include("6 indices updated")
      expect(response.body).to include(I18n.t("admin.logs.index.detalle"))
      expect(response.body).not_to include(I18n.t("admin.logs.index.detalle_error"))
      expect(response.body).not_to include("bg-negative-bg")
    end

    it "renders the error detail row as hidden with reveal target" do
      create(:system_log, :error, error_message: "Rate limit exceeded")
      get admin_logs_path

      expect(response.body).to include('data-reveal-target="content"')
      expect(response.body).to include('data-controller="reveal"')
    end
  end
end
