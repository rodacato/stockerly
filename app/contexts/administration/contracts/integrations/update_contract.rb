module Administration
  module Integrations
    class UpdateContract < ApplicationContract
      params do
        required(:id).filled(:integer)
        optional(:api_key_encrypted).maybe(:string)
        optional(:daily_call_limit).maybe(:integer)
        optional(:max_requests_per_minute).maybe(:integer)
      end

      rule(:daily_call_limit) do
        key.failure("must be positive") if value && value <= 0
      end

      rule(:max_requests_per_minute) do
        key.failure("must be positive") if value && value <= 0
      end
    end
  end
end
