module Identity
  class UpdateProfileContract < ApplicationContract
    params do
      required(:full_name).filled(:string, min_size?: 2)
      required(:email).filled(:string, format?: URI::MailTo::EMAIL_REGEXP)
    end
  end
end
