module Identity
  module Contracts
    class BugReportContract < ApplicationContract
      params do
        required(:title).filled(:string, min_size?: 3)
        required(:description).filled(:string, min_size?: 10)
      end
    end
  end
end
