class ProfilesController < AuthenticatedController
  def show
    result = Identity::LoadProfile.call(user: current_user)
    data = result.value!

    @watchlist_items = data[:watchlist_items]
    @market_status   = { us: MarketHours.us_market_open?, bmv: MarketHours.bmv_market_open?, crypto: true }
  end

  def update
    result = Identity::UpdateInfo.call(user: current_user, params: profile_params.to_h)

    case result
    in Dry::Monads::Success
      redirect_to profile_path, notice: "Profile updated successfully."
    in Dry::Monads::Failure[ :validation, errors ]
      flash.now[:alert] = errors.values.flatten.first
      render :show, status: :unprocessable_content
    end
  end

  def update_preferences
    result = Alerts::UpdatePreferences.call(
      user: current_user,
      params: preference_params.to_h.symbolize_keys
    )

    if result.success?
      head :ok
    else
      head :unprocessable_content
    end
  end

  def change_password
    result = Identity::ChangePassword.call(user: current_user, params: password_params.to_h)

    case result
    in Dry::Monads::Success
      redirect_to profile_path, notice: "Password changed successfully."
    in Dry::Monads::Failure[ :unauthorized, message ]
      redirect_to profile_path, alert: message
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to profile_path, alert: errors.values.flatten.first
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:full_name, :email)
  end

  def password_params
    params.require(:password_change).permit(:current_password, :password, :password_confirmation)
  end

  def preference_params
    params.permit(:email_digest, :browser_push, :sms_notifications)
  end
end
