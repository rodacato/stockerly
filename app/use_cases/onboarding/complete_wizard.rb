module Onboarding
  class CompleteWizard < ApplicationUseCase
    def call(user:, asset_ids:)
      assets = Asset.where(id: asset_ids)

      assets.each do |asset|
        user.watchlist_items.find_or_create_by!(asset: asset) do |item|
          item.entry_price = asset.current_price
        end
      end

      user.update!(onboarded_at: Time.current)

      Success(user)
    rescue ActiveRecord::RecordInvalid => e
      Failure([:validation, e.message])
    end
  end
end
