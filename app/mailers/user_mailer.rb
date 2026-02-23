class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: user.email, subject: "Welcome to Stockerly!")
  end

  def password_reset(user, reset_url)
    @user = user
    @reset_url = reset_url
    mail(to: user.email, subject: "Reset your Stockerly password")
  end

  def account_suspended(user)
    @user = user
    mail(to: user.email, subject: "Your Stockerly account has been suspended")
  end
end
