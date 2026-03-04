module Admin
  class OnboardingController < BaseController
    skip_before_action :redirect_to_onboarding

    before_action :require_not_onboarded

    def integrations
      @integrations = Integration.order(:provider_name)
    end

    def save_integrations
      keys = params[:api_keys]&.to_unsafe_h || {}
      Administration::UseCases::Onboarding::SaveApiKeys.call(keys: keys)
      redirect_to admin_onboarding_assets_path
    end

    def assets
      @catalog = Administration::Domain::AssetCatalog.all
    end

    def save_assets
      symbols = params[:symbols] || []
      Administration::UseCases::Onboarding::SeedAssets.call(symbols: symbols)
      redirect_to admin_onboarding_complete_path
    end

    def complete
      @integrations_configured = Integration.where.not(api_key_encrypted: nil).count
      @integrations_total = Integration.count
      @assets_count = Asset.count
    end

    def launch
      launch_sync = params[:launch_sync] != "false"
      Administration::UseCases::Onboarding::CompleteSetup.call(user: current_user, launch_sync: launch_sync)
      redirect_to admin_root_path, notice: "Setup complete! Your data is syncing."
    end

    private

    def require_not_onboarded
      redirect_to admin_root_path if current_user.onboarded?
    end
  end
end
