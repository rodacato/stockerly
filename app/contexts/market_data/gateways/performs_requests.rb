module MarketData
  module Gateways
    # The Faraday plumbing the HTTP gateways repeat: one memoised connection,
    # JSON responses, a timeout pair, and one rescue for transport errors.
    # Included rather than inherited because the nine that need it share no base
    # class — five extend MarketDataGateway, one FundamentalsGateway, three
    # nothing.
    #
    # What varies per provider stays in the provider: base URL, auth style,
    # timeout value and retry budget are all arguments, and both failure hooks
    # are overridable so a provider that knows more than its status code says
    # can still say it.
    module PerformsRequests
      private

      def build_connection(url:, timeout:, retry_options:, &block)
        @connection ||= Faraday.new(url: url) do |f|
          f.request :retry, RetryPolicy.options(retry_options)
          f.response :json
          f.options.timeout = timeout
          f.options.open_timeout = timeout
          block&.call(f)
        end
      end

      # Returns Success(the parsed body) or the failure the hooks below decide.
      def get_json(path, params = {}, &block)
        response = connection.get(path) do |req|
          req.params.update(params.transform_keys(&:to_s))
          block&.call(req)
        end

        return failure_from(response) unless response.success?

        Success(response.body)
      rescue Faraday::Error => e
        transport_failure(e)
      end

      def failure_from(response)
        GatewayFailure.from(response, self.class::PROVIDER)
      end

      def transport_failure(error)
        Failure([ :gateway_error, error.message ])
      end
    end
  end
end
