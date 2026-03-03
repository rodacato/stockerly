module Administration
  module Contracts
    module Assets
      class CreateContract < ApplicationContract
        params do
          required(:symbol).filled(:string)
          required(:name).filled(:string)
          required(:asset_type).filled(:string, included_in?: %w[stock crypto index etf])
          optional(:country).maybe(:string)
          optional(:exchange).maybe(:string)
          optional(:sector).maybe(:string)
          optional(:logo_url).maybe(:string)
        end

        rule(:symbol) do
          key.failure("must be 1-20 uppercase alphanumeric characters") unless /\A[A-Z0-9.\-\/]{1,20}\z/.match?(value)
        end

        rule(:symbol) do
          key.failure("already exists") if Asset.exists?(symbol: value)
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
