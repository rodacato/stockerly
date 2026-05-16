class BugReportMailer < ApplicationMailer
  def notify(user:, title:, description:)
    @user = user
    @title = title
    @description = description

    mail(
      to: "support@notdefined.dev",
      reply_to: user.email,
      subject: "[Beta bug] #{title.truncate(60)}"
    )
  end
end
