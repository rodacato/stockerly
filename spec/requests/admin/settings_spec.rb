require "rails_helper"

RSpec.describe "Admin settings", type: :request do
  let!(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "PATCH /admin/settings" do
    it "saves the toggles and says so" do
      patch admin_settings_path, params: { developer_mode: "1" }

      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Ajustes guardados.")
      expect(SiteConfig.find_by(key: "developer_mode").value).to eq("true")
    end
  end
end
