module Administration
  module Contracts
    module Integrations
      class ConnectContract < ApplicationContract
        params do
          required(:provider_name).filled(:string)
          required(:provider_type).filled(:string)
          optional(:api_key_encrypted).maybe(:string)
        end
      end
    end
  end
end
