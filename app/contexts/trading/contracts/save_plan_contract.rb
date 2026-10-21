module Trading
  module Contracts
    class SavePlanContract < ApplicationContract
      params do
        required(:stocks_share).filled(:integer, gteq?: 0, lteq?: 100)
        required(:crypto_share).filled(:integer, gteq?: 0, lteq?: 100)
        required(:fixed_income_share).filled(:integer, gteq?: 0, lteq?: 100)
        required(:monthly_contribution).filled(:decimal, gteq?: 0)
      end

      rule(:stocks_share, :crypto_share, :fixed_income_share) do
        total = values[:stocks_share] + values[:crypto_share] + values[:fixed_income_share]
        key(:fixed_income_share).failure(I18n.t("plans.errors.suma", total: total, missing: 100 - total)) unless total == 100
      end
    end
  end
end
