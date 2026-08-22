class ProfilesController < AuthenticatedController
  # Loads the data the IdentityCard sidebar needs once at the
  # controller level so the view doesn't perform DB queries inline.
  # Keeps MVC clean and lets us compose a cheap counts query.
  def show
    @sidebar = identity_card_counts
  end

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

  # Dedicated endpoint for the preferred-currency segmented control.
  # Splitting this out of #update avoids the hidden-field pattern (which
  # risks stale-data overwrites of full_name/email if the user has the
  # profile open in multiple tabs). UpdateInfo still owns the canonical
  # write — we just pass current values explicitly.
  def update_currency
    currency = params.dig(:profile, :preferred_currency).to_s.strip
    unless Asset::SUPPORTED_CURRENCIES.include?(currency)
      redirect_to profile_path, alert: "Moneda no soportada."
      return
    end

    result = Identity::UseCases::UpdateInfo.call(
      user: current_user,
      params: { full_name: current_user.full_name, email: current_user.email, preferred_currency: currency }
    )

    case result
    in Dry::Monads::Success
      redirect_to profile_path, notice: "Moneda actualizada."
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to profile_path, alert: errors.values.flatten.first
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

  # Precompute the IdentityCard sidebar counts at the controller layer
  # so the view doesn't issue DB queries. Three COUNTs run in parallel
  # at the SQL level when the relation is laid out this way.
  def identity_card_counts
    portfolio = current_user.portfolio
    {
      open_positions:   portfolio&.positions&.where(status: :open)&.count || 0,
      watchlist_items:  current_user.watchlist_items.count,
      active_alerts:    current_user.alert_rules.where(status: :active).count
    }
  end
end
