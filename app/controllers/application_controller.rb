class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= if session[:user_id]
      User.find_by(id: session[:user_id])
    else
      user_from_remember_cookie
    end
  end

  def logged_in?
    current_user.present?
  end

  def start_session(user)
    reset_session
    session[:user_id] = user.id
  end

  def remember(user)
    token_record, raw_token = RememberToken.generate(
      user,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    cookies.signed[:remember_token] = {
      value: "#{token_record.id}:#{raw_token}",
      expires: 30.days.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  def forget(user)
    if cookies.signed[:remember_token].present?
      token_id, _ = cookies.signed[:remember_token].split(":", 2)
      user.remember_tokens.find_by(id: token_id)&.destroy
    end
    cookies.delete(:remember_token)
  end

  def user_from_remember_cookie
    return unless cookies.signed[:remember_token].present?

    token_id, raw_token = cookies.signed[:remember_token].split(":", 2)
    return unless token_id.present? && raw_token.present?

    token_record = RememberToken.active.find_by(id: token_id)
    return unless token_record

    digest = Digest::SHA256.hexdigest(raw_token)
    return unless ActiveSupport::SecurityUtils.secure_compare(token_record.token_digest, digest)

    token_record.touch_last_used!
    start_session(token_record.user)
    token_record.user
  end
end
