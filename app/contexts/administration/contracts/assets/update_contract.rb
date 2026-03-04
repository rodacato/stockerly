module Administration
  module Contracts
    module Assets
      class UpdateContract < ApplicationContract
        params do
          required(:id).filled(:integer)
          optional(:name).maybe(:string)
          optional(:logo_url).maybe(:string)
          optional(:sector).maybe(:string)
          optional(:exchange).maybe(:string)
          optional(:country).maybe(:string)
        end

        rule(:name) do
          key.failure("must not be blank") if key? && value.is_a?(String) && value.strip.empty?
        end

        rule(:country) do
          key.failure("must be a 2-letter ISO code") if value.present? && !/\A[A-Z]{2}\z/.match?(value)
        end

        rule(:logo_url) do
          key.failure("must be a valid HTTPS URL") if value.present? && !value.start_with?("https://")
        end
      end
    end
  end
end
