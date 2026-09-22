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
    load_integrations
  end

  def save_integrations
    keys = params[:api_keys]&.to_unsafe_h || {}
    result = Administration::UseCases::Onboarding::SaveApiKeys.call(keys: keys)

    return render_fx_failure if result[:fx] == :failed

    redirect_to onboarding_assets_path, notice: fx_notice(result[:fx])
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
    keyed = Integration.all.select { |i| MarketData::Domain::ProviderDirectory.for(i.provider_name)&.requires_key }
    @integrations_configured = keyed.count { |i| i.api_key_encrypted.present? }
    @integrations_total = keyed.size
    @assets_count = Asset.count
    @queue_attended = HealthMetrics.queue_attended?
  end

  def launch
    launch_sync = params[:launch_sync] != "false"
    Administration::UseCases::Onboarding::LaunchInitialSync.call(launch_sync: launch_sync)
    redirect_to welcome_path
  end

  private

  def load_integrations
    @integrations = Integration.order(:provider_name)
  end

  # The Banxico pull is the only key the wizard can exercise on the spot, so its
  # outcome belongs on the step that asked for the key rather than over the next.
  def render_fx_failure
    flash.now[:alert] = t("onboarding.integraciones.tc_error")
    load_integrations
    render :integrations, status: :unprocessable_content
  end

  def fx_notice(outcome)
    return unless outcome.is_a?(Integer)

    t("onboarding.integraciones.tc_listo", count: outcome)
  end

  def require_not_onboarded
    redirect_to dashboard_path if current_user.onboarded?
  end
end
