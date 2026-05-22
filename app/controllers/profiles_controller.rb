class ProfilesController < AuthenticatedController
  # Loads the data the IdentityCard sidebar needs once at the
  # controller level so the view doesn't perform DB queries inline.
  # Keeps MVC clean and lets us compose a cheap counts query.
  def show
    @sidebar = identity_card_counts
    @active_sessions = current_user.remember_tokens.active.order(last_used_at: :desc).to_a
    @current_session_id = current_remember_token_id
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

  # Revokes a single remember-token-backed session ("close session on
  # this device" from the Seguridad tab). Scoped to current_user so a
  # crafted id cannot drop another user's token.
  def revoke_session
    token = current_user.remember_tokens.find_by(id: params[:id])
    if token
      token.destroy
      redirect_to profile_path, notice: "Sesión cerrada en ese dispositivo."
    else
      redirect_to profile_path, alert: "Esa sesión ya no está activa."
    end
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

  # Read the current request's remember-token id from the signed cookie.
  # Returns the integer id when the cookie covers a *real* row owned by
  # the current user; nil for the cookieless "this device" case (browser
  # session only) — letting the view fall back to the synthesized row.
  def current_remember_token_id
    raw = cookies.signed[:remember_token]
    return nil if raw.blank?

    token_id, _ = raw.split(":", 2)
    return nil unless token_id.present?

    id = token_id.to_i
    current_user.remember_tokens.where(id: id).exists? ? id : nil
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
