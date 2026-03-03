module Administration
  module Contracts
    module Integrations
      class AddPoolKeyContract < ApplicationContract
        params do
          required(:integration_id).filled(:integer)
          required(:name).filled(:string)
          required(:api_key_encrypted).filled(:string)
        end
      end
    end
  end
end
