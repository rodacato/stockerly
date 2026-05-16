module Identity
  module UseCases
    class SendBugReport < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Contracts::BugReportContract, params)

        BugReportMailer.notify(
          user: user,
          title: attrs[:title],
          description: attrs[:description]
        ).deliver_later

        Success(attrs)
      end
    end
  end
end
