class BugReportMailer < ApplicationMailer
  def notify(user:, title:, description:)
    @user = user
    @title = title
    @description = description

    mail(
      to: Stockerly::SUPPORT_EMAIL,
      reply_to: user.email,
      subject: "[Bug beta] #{title.truncate(60)}"
    )
  end
end
