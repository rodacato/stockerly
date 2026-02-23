class OnboardingController < AuthenticatedController
  def step1; end

  def step2
    result = Onboarding::LoadAssetCatalog.call
    @assets = result.value![:assets]
  end

  def complete
    asset_ids = params[:asset_ids] || []
    Onboarding::CompleteWizard.call(user: current_user, asset_ids: asset_ids)

    redirect_to onboarding_step3_path, notice: "Watchlist created!"
  end

  def skip
    current_user.update!(onboarded_at: Time.current)
    redirect_to dashboard_path, notice: "You can always add stocks from the Market page."
  end

  def step3
    result = Onboarding::LoadProgress.call(user: current_user)
    @watchlist_count = result.value![:watchlist_count]
  end
end
