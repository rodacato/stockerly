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
          optional(:currency).maybe(:string, included_in?: Asset::SUPPORTED_CURRENCIES)
        end

        # Deferred to the model rather than re-derived: this rule only turns the
        # same shape into a message the wizard can show.
        rule(:symbol) do
          key.failure(:invalid_symbol_format) unless Asset::SYMBOL_FORMAT.match?(value)
        end

        rule(:symbol) do
          key.failure(:already_exists) if Asset.exists?(symbol: value)
        end

        rule(:country) do
          key.failure(:invalid_country_code) if value.present? && !/\A[A-Z]{2}\z/.match?(value)
        end

        rule(:logo_url) do
          key.failure(:invalid_https_url) if value.present? && !value.start_with?("https://")
        end
      end
    end
  end
end
