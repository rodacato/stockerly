class UserMailer < ApplicationMailer
  def password_reset(user, reset_url)
    @user = user
    @reset_url = reset_url
    mail(to: user.email, subject: t(".subject"))
  end
end
