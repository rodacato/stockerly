class OnboardingController < AuthenticatedController
  def step1; end

  def step2
    @assets = Asset.where(asset_type: [:stock, :crypto]).order(:name).limit(20)
  end

  def complete
    asset_ids = params[:asset_ids] || []
    Onboarding::CompleteWizard.call(user: current_user, asset_ids: asset_ids)

    redirect_to "/onboarding/step3", notice: "Watchlist created!"
  end

  def step3
    @watchlist_count = current_user.watchlist_items.count
  end
end
