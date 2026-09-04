require "rails_helper"

# §6b moved the screen title into the shell bar, and the admin views kept
# writing content_for(:admin_page_title) — a key the surviving layout does not
# read. Nothing failed: the bar quietly fell back to a nav label and the tab to
# the pre-pivot English tagline. These pin both so the orphan cannot come back.
RSpec.describe "Page titles", type: :request do
  let(:user) { create(:user, :admin, onboarded_at: Time.current, password: "password123") }

  before { post login_path, params: { email: user.email, password: "password123" } }

  {
    "/admin/logs"         => "Registros",
    "/admin/integrations" => "Integraciones",
    "/admin/settings"     => "Estado y mantenimiento"
  }.each do |path, name|
    it "names #{path} in the tab and in the shell bar" do
      get path

      expect(response.body).to include("<title>#{name} | Stockerly</title>")
      expect(response.body).to include(name)
    end
  end

  it "no longer writes a key nothing reads" do
    expect(Rails.root.glob("app/views/**/*.erb").select { |f|
      File.read(f).include?("admin_page_title")
    }).to be_empty
  end
end
