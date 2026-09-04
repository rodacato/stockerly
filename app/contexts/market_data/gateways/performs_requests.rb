module MarketData
  module Gateways
    # The Faraday plumbing the HTTP gateways repeat: one memoised connection,
    # JSON responses and a timeout pair. Included rather than inherited because
    # the nine that need it share no base class — five extend MarketDataGateway,
    # one FundamentalsGateway, three nothing.
    #
    # What varies per provider stays in the provider: base URL, auth style,
    # timeout value and retry budget are all arguments.
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
    end
  end
end
