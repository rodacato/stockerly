module MarketData
  module Gateways
    # PROVIDER is read off the including class rather than lexically: the eight
    # gateways that need a key share no base class to hang this on.
    module ResolvesApiKey
      private

      def resolve_api_key
        provider = self.class::PROVIDER
        key = ApiKeyResolver.for(provider)
        raise ApiKeyNotConfiguredError.new(provider) if key.blank?
        key
      rescue ActiveRecord::Encryption::Errors::Decryption
        raise ApiKeyNotConfiguredError.new(provider, reason: "decryption failed")
      end
    end
  end
end
