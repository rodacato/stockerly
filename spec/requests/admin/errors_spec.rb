require "rails_helper"

RSpec.describe "Admin errors", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  def enable_developer_mode
    SiteConfig.set("developer_mode", true)
  end

  describe "the developer_mode gate" do
    before { login_as(admin) }

    it "sends the owner back to settings while the switch is off" do
      get admin_errors_path

      expect(response).to redirect_to(admin_settings_path)
    end

    it "opens the list once the switch is on" do
      enable_developer_mode

      get admin_errors_path

      expect(response).to have_http_status(:ok)
    end

    it "hides a stored backtrace while the switch is off" do
      create(:error_event, backtrace: [ "app/models/secret_place.rb:3:in `call'" ])

      get admin_errors_path

      expect(response.body).not_to include("secret_place.rb")
    end
  end

  describe "what an anonymous visitor gets" do
    it "is a redirect to login, switch on or off" do
      enable_developer_mode

      get admin_errors_path

      expect(response).to redirect_to(login_path)
    end

    it "is a redirect to login on the detail screen too" do
      enable_developer_mode
      event = create(:error_event)

      get admin_error_path(event)

      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /admin/errors" do
    before do
      login_as(admin)
      enable_developer_mode
    end

    it "lists the exception class and where it came from" do
      create(:error_event, exception_class: "ActiveRecord::RecordInvalid", request_path: "/trades")

      get admin_errors_path

      expect(response.body).to include("ActiveRecord::RecordInvalid")
      expect(response.body).to include("/trades")
    end

    it "narrows to one origin when asked" do
      create(:error_event, exception_class: "FromARequest")
      create(:error_event, :job, exception_class: "FromAJob")

      get admin_errors_path(source: "job")

      expect(response.body).to include("FromAJob")
      expect(response.body).not_to include("FromARequest")
    end

    it "searches by message" do
      create(:error_event, exception_class: "Wanted", message: "connection refused")
      create(:error_event, exception_class: "Unwanted", message: "something else")

      get admin_errors_path(search: "connection")

      expect(response.body).to include("Wanted")
      expect(response.body).not_to include("Unwanted")
    end

    it "searches by the job class its origin chip shows" do
      create(:error_event, :job, exception_class: "Wanted", job_class: "SyncFundamentalJob")
      create(:error_event, exception_class: "Unwanted")

      get admin_errors_path(search: "SyncFundamental")

      expect(response.body).to include("Wanted")
      expect(response.body).not_to include("Unwanted")
    end

    # F4.2: a hand-edited page is the first page, not a 500.
    it "reads a page that is not a page number as the first one" do
      create(:error_event, exception_class: "Listed")

      %w[abc 0 -1].each do |page|
        get admin_errors_path(page: page)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Listed")
      end
    end

    it "names the search that matched nothing" do
      get admin_errors_path(search: "nada-de-esto")

      expect(response.body).to include(ERB::Util.h(I18n.t("admin.errors.index.sin_coincidencias_busqueda", search: "nada-de-esto")))
    end

    it "says nothing about the page while every error fits on it" do
      create(:error_event)

      get admin_errors_path

      expect(response.body).not_to include("Mostrando")
    end

    it "says the list is empty rather than rendering nothing" do
      get admin_errors_path

      expect(response.body).to include("no ha registrado ningún error")
    end
  end

  describe "GET /admin/errors/:id" do
    before do
      login_as(admin)
      enable_developer_mode
    end

    it "shows the backtrace, which is the reason to open it" do
      event = create(:error_event, backtrace: [ "app/models/thing.rb:12:in `call'" ])

      get admin_error_path(event)

      expect(response.body).to include("app/models/thing.rb:12")
    end

    it "says the request it shows is the latest one, once the error repeated" do
      once = create(:error_event, occurrences: 1)
      again = create(:error_event, occurrences: 4)

      get admin_error_path(once)
      expect(response.body).not_to include(I18n.t("admin.errors.show.de_la_ultima_vez"))

      get admin_error_path(again)
      expect(response.body).to include(I18n.t("admin.errors.show.de_la_ultima_vez"))
    end

    it "draws no line and no trace for an error raised outside the app's code" do
      event = create(:error_event, app_line: Administration::Domain::ErrorFingerprint::UNKNOWN_LINE, backtrace: [])

      get admin_error_path(event)

      expect(response.body).not_to include(">unknown<", I18n.t("admin.errors.show.traza"))
    end

    it "sends the owner back to the list when the row is gone" do
      get admin_error_path(id: 999_999)

      expect(response).to redirect_to(admin_errors_path)
    end
  end

  describe "DELETE /admin/errors/:id" do
    before do
      login_as(admin)
      enable_developer_mode
    end

    it "removes the row once the bug behind it is fixed" do
      event = create(:error_event)

      expect { delete admin_error_path(event) }.to change(ErrorEvent, :count).by(-1)
      expect(response).to redirect_to(admin_errors_path)
    end
  end
end
