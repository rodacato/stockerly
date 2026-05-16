module Identity
  module UseCases
    # ADR-006: trivial single-resource mutation, no validation, no events → SimpleUseCase.
    class CompleteOnboarding < SimpleUseCase
      def call(user:)
        user.update!(onboarded_at: Time.current)
        user
      end
    end
  end
end
