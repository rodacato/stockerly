module Identity
  module Contracts
    class UpdateProfileContract < ApplicationContract
      params do
        required(:full_name).filled(:string, min_size?: 2)
        required(:email).filled(:string, format?: URI::MailTo::EMAIL_REGEXP)
        optional(:preferred_currency).maybe(:string, included_in?: Asset::SUPPORTED_CURRENCIES)
      end
    end
  end
end
