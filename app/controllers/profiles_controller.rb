class ProfilesController < AuthenticatedController
  def show; end

  def update
    result = Identity::UseCases::UpdateInfo.call(user: current_user, params: profile_params.to_h)

    case result
    in Dry::Monads::Success
      redirect_to profile_path, notice: "Perfil actualizado."
    in Dry::Monads::Failure[ :validation, errors ]
      flash.now[:alert] = errors.values.flatten.first
      render :show, status: :unprocessable_content
    end
  end

  def update_preferences
    Alerts::UseCases::UpdatePreferences.call(
      user: current_user,
      params: preference_params.to_h.symbolize_keys
    )
    head :ok
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  def change_password
    result = Identity::UseCases::ChangePassword.call(user: current_user, params: password_params.to_h)

    case result
    in Dry::Monads::Success
      redirect_to profile_path, notice: "Contraseña cambiada correctamente."
    in Dry::Monads::Failure[ :unauthorized, message ]
      redirect_to profile_path, alert: message
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to profile_path, alert: errors.values.flatten.first
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:full_name, :email, :preferred_currency)
  end

  def password_params
    params.require(:password_change).permit(:current_password, :password, :password_confirmation)
  end

  def preference_params
    params.permit(:email_digest, :browser_push, :sms_notifications)
  end
end
