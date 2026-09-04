require "rails_helper"

# KIT-3: the kit promoted `HeaderBar` after two flows hand-built it six times,
# and the code had no equivalent — so on a phone the screens behind the hub
# were a one-way trip. The bar replaces the mobile TopBar, which is why the
# layout's sr-only h1 has to step aside for it.
RSpec.describe "HeaderBar", type: :request do
  let(:user) { create(:user, :admin, onboarded_at: Time.current) }

  before { login_as(user) }

  # The two flows the artboards cover: settings.pen goes back to the hub,
  # alerts.pen's Bandeja back to the rules it belongs to (D13).
  {
    "/admin/logs" => :settings_path,
    "/admin/settings" => :settings_path,
    "/admin/integrations" => :settings_path,
    "/notifications" => :alerts_path
  }.each do |path, back|
    it "gives #{path} a way back to #{back}" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(aria-label="#{I18n.t("nav.regresar")}"))
      expect(response.body).to match(/href="#{send(back)}"[^>]*>\s*<span[^>]*>arrow_back/m)
    end

    it "heads #{path} with the visible title instead of the sr-only one" do
      get path

      doc = response.parsed_body
      mobile = doc.css("h1").reject { |h| h["class"].to_s.include?("sr-only") }

      expect(mobile.map { |node| node.text.strip }).to include(page_title_for(path))
      expect(doc.css("h1.sr-only")).to be_empty
    end
  end

  # The negative case: a tab destination keeps the logo+bell bar. A back arrow
  # on a root screen would point at nothing.
  it "leaves the logo+bell bar on a tab destination" do
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(%(aria-label="#{I18n.t("nav.regresar")}"))
    expect(response.parsed_body.css("h1.sr-only")).not_to be_empty
  end

  def page_title_for(path)
    {
      "/admin/logs" => I18n.t("admin.logs.index.titulo"),
      "/admin/settings" => I18n.t("admin.settings.show.titulo"),
      "/admin/integrations" => I18n.t("admin.integrations.index.titulo"),
      "/notifications" => I18n.t("notifications.index.titulo")
    }.fetch(path)
  end
end
