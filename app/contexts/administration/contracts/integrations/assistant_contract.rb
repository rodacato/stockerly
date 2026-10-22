require "ipaddr"

module Administration
  module Contracts
    module Integrations
      class AssistantContract < ApplicationContract
        params do
          required(:base_url).filled(:string)
          required(:model).filled(:string)
          optional(:api_key).maybe(:string)
        end

        # The key travels in a header, so plain http is allowed only where it
        # never leaves the owner's network (SheLLM or Ollama on the LAN).
        rule(:base_url) do
          uri = URI.parse(value)
          key.failure(:insecure_host) unless uri.host && (uri.scheme == "https" || (uri.scheme == "http" && private_host?(uri.host)))
        rescue URI::InvalidURIError
          key.failure(:insecure_host)
        end

        def private_host?(host)
          return true if host == "localhost"

          address = IPAddr.new(host)
          address.private? || address.loopback?
        rescue IPAddr::InvalidAddressError
          false
        end
      end
    end
  end
end
