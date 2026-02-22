class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: user.email, subject: "Welcome to Stockerly!")
  end

  def account_suspended(user)
    @user = user
    mail(to: user.email, subject: "Your Stockerly account has been suspended")
  end
end
