class OnboardingController < AuthenticatedController
  layout "onboarding"

  # Four since D52: integraciones · activos · seguridad · listo. The security
  # step OFFERS enrolment and lets the reader skip — it is step 3 and not step
  # 1 on purpose, so the recovery codes land next to a wizard already invested
  # in rather than on the screen a reader is most likely to rush.
  STEPS = 4

  skip_before_action :redirect_to_onboarding

  before_action :require_not_onboarded

  def integrations
    @integrations = Integration.order(:provider_name)
  end

  def save_integrations
    keys = params[:api_keys]&.to_unsafe_h || {}
    result = Administration::UseCases::Onboarding::SaveApiKeys.call(keys: keys)

    redirect_to onboarding_assets_path, notice: fx_notice(result.value![:fx])
  end

  def assets
    @catalog = Administration::Domain::AssetCatalog.all
  end

  def security; end

  def save_assets
    symbols = params[:symbols] || []
    Administration::UseCases::Onboarding::SeedAssets.call(symbols: symbols)
    redirect_to onboarding_security_path
  end

  def complete
    @integrations_configured = Integration.where.not(api_key_encrypted: nil).count
    @integrations_total = Integration.count
    @assets_count = Asset.count
  end

  def launch
    launch_sync = params[:launch_sync] != "false"
    Administration::UseCases::Onboarding::LaunchInitialSync.call(launch_sync: launch_sync)
    redirect_to welcome_path
  end

  private

  # The Banxico pull is the only key the wizard can exercise on the spot, so its
  # outcome is worth saying out loud rather than leaving to a later sync.
  def fx_notice(outcome)
    case outcome
    in Integer => stored then t("onboarding.integraciones.tc_listo", count: stored)
    in :failed then t("onboarding.integraciones.tc_error")
    else nil
    end
  end

  def require_not_onboarded
    redirect_to dashboard_path if current_user.onboarded?
  end
end
