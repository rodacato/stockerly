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
end
