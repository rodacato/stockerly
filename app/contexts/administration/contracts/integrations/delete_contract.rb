module Administration
  module Integrations
    class DeleteContract < ApplicationContract
      params do
        required(:id).filled(:integer)
      end
    end
  end
end
