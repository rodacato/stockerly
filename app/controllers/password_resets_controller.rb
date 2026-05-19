class PasswordResetsController < ApplicationController
  layout "public"

  INVALID_TOKEN_MESSAGE = "El enlace de restablecimiento es inválido o expiró.".freeze
  private_constant :INVALID_TOKEN_MESSAGE

  rate_limit to: 3, within: 1.hour, only: :create

  before_action :find_user_by_token, only: [ :edit ]

  def new; end

  def create
    Identity::UseCases::RequestPasswordReset.call(params: { email: params[:email] })
    redirect_to login_path, notice: "Si ese correo está registrado, recibirás instrucciones para restablecer tu contraseña en unos minutos."
  end

  def edit; end

  def update
    result = Identity::UseCases::ResetPassword.call(token: params[:token], params: password_params.to_h)

    case result
    in Dry::Monads::Success
      redirect_to login_path, notice: "Contraseña restablecida correctamente. Inicia sesión con tu nueva contraseña."
    in Dry::Monads::Failure[ :invalid_token ]
      redirect_to forgot_password_path, alert: INVALID_TOKEN_MESSAGE
    in Dry::Monads::Failure[ :validation, user ]
      @user = user
      render :edit, status: :unprocessable_content
    end
  end

  private

  def find_user_by_token
    @user = User.find_by_password_reset_token(params[:token])
    redirect_to forgot_password_path, alert: INVALID_TOKEN_MESSAGE unless @user
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
