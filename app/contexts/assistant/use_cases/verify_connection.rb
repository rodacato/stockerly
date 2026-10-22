module Assistant
  module UseCases
    # One request to the configured host, so the owner knows it answers before
    # anything is asked of it. Administration records the outcome.
    class VerifyConnection < ApplicationUseCase
      def call
        connection = Administration::Queries::AssistantConnection.call
        return Failure([ :not_configured ]) if connection.nil?

        verification = Gateways::AnthropicMessages.new(base_url: connection[:base_url], api_key: connection[:api_key].to_s,
                                                       model: connection[:model]).verify
        yield publish(Events::ConnectionVerified.new(status: verification.status.to_s))

        Success(verification)
      end
    end
  end
end
