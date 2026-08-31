module Identity
  module UseCases
    # Removes the account and everything belonging to it, returning the instance
    # to the Setup Wizard — `ApplicationController#redirect_to_setup` sends every
    # request there once no user exists.
    #
    # What survives is instance infrastructure, not personal data: the asset
    # catalogue, the FX and price history, and the configured integrations. A
    # fresh install has those too, and re-entering the API keys is a cost the
    # word "clean start" does not imply.
    class DeleteAccount < SimpleUseCase
      def call(user:)
        user.destroy!
      end
    end
  end
end
