class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: user.email, subject: "Bienvenido a Stockerly")
  end

  def password_reset(user, reset_url)
    @user = user
    @reset_url = reset_url
    mail(to: user.email, subject: "Restablece tu contraseña de Stockerly")
  end

  def account_suspended(user)
    @user = user
    mail(to: user.email, subject: "Tu cuenta de Stockerly fue suspendida")
  end

  def account_reactivated(user)
    @user = user
    mail(to: user.email, subject: "Tu cuenta de Stockerly fue reactivada")
  end
end
