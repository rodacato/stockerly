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

  def verify_email(user, verification_url)
    @user = user
    @verification_url = verification_url
    mail(to: user.email, subject: "Verify your Stockerly email")
  end

  def account_suspended(user)
    @user = user
    mail(to: user.email, subject: "Your Stockerly account has been suspended")
  end

  def account_reactivated(user)
    @user = user
    mail(to: user.email, subject: "Your Stockerly account has been reactivated")
  end
end
