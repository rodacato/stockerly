module Admin
  class SettingsController < BaseController
    def show
      @registration_open = SiteConfig.registration_open?
      @maintenance_mode = SiteConfig.maintenance_mode?
    end

    def update
      SiteConfig.set("registration_open", params[:registration_open] == "1")
      SiteConfig.set("maintenance_mode", params[:maintenance_mode] == "1")

      redirect_to admin_settings_path, notice: "Settings updated."
    end
  end
end
