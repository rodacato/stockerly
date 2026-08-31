class SettingsController < AuthenticatedController
  # The Ajustes hub (D5): on a single-user instance the admin split was a
  # costume. One screen with sections, linking to the surfaces that already
  # exist rather than reimplementing them.
  def show
    @user = current_user
    @preferences = current_user.alert_preference
    @integrations_count = Integration.count
    @developer_mode = SiteConfig.developer_mode?
    @trading_counts = trading_counts
  end

  # Reloading a broker archive means clearing what is there first. Everything
  # this removes descends from a trade; the catalogue and the rate history stay,
  # because re-fetching them costs provider calls and neither is personal data.
  def destroy_trading_data
    Trading::UseCases::ResetPortfolioData.call(portfolio: current_user.portfolio)

    redirect_to settings_path, notice: t(".listo")
  end

  # The account and everything belonging to it. Once no user exists every
  # request lands on the Setup Wizard, so the session goes with it.
  def destroy_account
    Identity::UseCases::DeleteAccount.call(user: current_user)
    reset_session

    redirect_to setup_path, notice: t(".listo")
  end

  private

  def trading_counts
    portfolio = current_user.portfolio
    return {} unless portfolio

    Trading::UseCases::ResetPortfolioData.counts(portfolio)
  end
end
