module Administration
  module UseCases
    module Onboarding
      class CompleteSetup < ApplicationUseCase
        def call(user:, launch_sync: false)
          user.update!(onboarded_at: Time.current)

          if launch_sync
            SyncPriorityAssetsJob.perform_later("stock", "high") if Asset.where(asset_type: :stock).exists?
            SyncPriorityAssetsJob.perform_later("crypto", "high") if Asset.where(asset_type: :crypto).exists?
            RefreshFxRatesJob.perform_later
            SyncMarketIndicesJob.perform_later
          end

          Success({ onboarded: true })
        end
      end
    end
  end
end
