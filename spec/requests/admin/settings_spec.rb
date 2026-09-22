require "rails_helper"

RSpec.describe "Admin settings", type: :request do
  let!(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  # AJ-11: Diagnóstico is the screen that says whether the instance is well,
  # and two of its eight rows carry a verdict rather than a fact.
  describe "GET /admin/settings" do
    it "distinguishes a queue with no worker from an idle one" do
      get admin_settings_path

      expect(response.body).to include(I18n.t("admin.settings.show.trabajos_workers", count: 0))
    end

    it "names the workers attending the queue" do
      register_queue_worker

      get admin_settings_path

      expect(response.body).to include(I18n.t("admin.settings.show.trabajos_workers", count: 1))
      expect(response.body).not_to include(I18n.t("admin.settings.show.trabajos_workers", count: 0))
    end

    it "marks the jobs row when nothing is attending the queue" do
      get admin_settings_path

      expect(jobs_row(response.body)).to include("text-warning-fg")
    end

    it "leaves the jobs row unmarked once a worker is attending" do
      register_queue_worker

      get admin_settings_path

      expect(jobs_row(response.body)).not_to include("text-warning-fg")
    end

    it "marks the errors row once something has failed in the last day" do
      create(:error_event, occurrences: 3, last_seen_at: 1.hour.ago)

      get admin_settings_path

      expect(errors_row(response.body)).to include("text-warning-fg")
    end

    it "leaves the errors row unmarked when the day was clean" do
      register_queue_worker

      get admin_settings_path

      expect(errors_row(response.body)).not_to include("text-warning-fg")
    end

    # The other six rows are facts, not verdicts, and must stay the same grey.
    it "marks only the two rows that carry a verdict" do
      create(:error_event, occurrences: 3, last_seen_at: 1.hour.ago)

      get admin_settings_path

      expect(diagnostics(response.body).scan("text-warning-fg").size).to eq(2)
    end

    def diagnostics(body)
      body[/<dl[^>]*>.*?<\/dl>/m]
    end

    def jobs_row(body)
      row(body, I18n.t("admin.settings.show.trabajos"))
    end

    def errors_row(body)
      row(body, I18n.t("admin.settings.show.errores"))
    end

    def row(body, label)
      diagnostics(body)[/<div[^>]*>\s*<dt[^>]*>#{Regexp.escape(label)}<\/dt>.*?<\/div>/m] ||
        raise("no row labelled #{label}")
    end
  end

  describe "PATCH /admin/settings" do
    it "saves the toggles and says so" do
      patch admin_settings_path, params: { developer_mode: "1" }

      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Ajustes guardados.")
      expect(SiteConfig.find_by(key: "developer_mode").value).to eq("true")
    end
  end
end
