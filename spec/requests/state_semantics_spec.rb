require "rails_helper"

# role="switch", aria-checked and aria-expanded appeared nowhere: every toggle
# and every disclosure in the app was a <button> whose state only existed in a
# class name.
RSpec.describe "State semantics", type: :request do
  let!(:admin) do
    create(:user, :admin, email: "estado@example.com", password: "password123",
                          onboarded_at: Time.current)
  end

  before { login_as(admin) }

  def switches
    response.parsed_body.css(%([role="switch"])).to_h { |node| [ node["aria-label"], node["aria-checked"] ] }
  end

  describe "the instance switches" do
    it "says of each switch whether it is on" do
      SiteConfig.set("maintenance_mode", true)

      get admin_settings_path

      expect(switches[I18n.t("admin.settings.show.mantenimiento")]).to eq("true")
      expect(switches[I18n.t("admin.settings.show.desarrollador")]).to eq("false")
    end
  end

  describe "the notification switches" do
    it "reads the stored preference rather than a class name" do
      create(:alert_preference, user: admin, email_digest: false, urgent_email: true)

      get settings_path

      expect(switches[I18n.t("settings.show.digest")]).to eq("false")
      expect(switches[I18n.t("settings.show.urgente")]).to eq("true")
    end
  end

  describe "the disclosures" do
    it "says a collapsed panel is collapsed" do
      create(:system_log, :error, error_message: "Gateway timeout")

      get admin_logs_path

      trigger = response.parsed_body.at_css(%([data-reveal-target="trigger"]))
      expect(trigger["aria-expanded"]).to eq("false")
    end

    it "turns the chevron with the panel rather than leaving it pointing down" do
      create(:system_log, :error, error_message: "Gateway timeout")

      get admin_logs_path

      chevron = response.parsed_body.at_css(%([data-reveal-target="trigger"] svg))
      expect(chevron["class"]).to include("group-aria-expanded:rotate-180")
    end
  end
end
