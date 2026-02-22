module Onboarding
  class CompleteWizard < ApplicationUseCase
    def call(user:, asset_ids:)
      assets = Asset.where(id: asset_ids)

      assets.each do |asset|
        user.watchlist_items.find_or_create_by!(asset: asset) do |item|
          item.entry_price = asset.current_price
        end
      end

      user.update!(onboarding_completed: true) if user.respond_to?(:onboarding_completed)

      Success(user)
    end
  end
end
