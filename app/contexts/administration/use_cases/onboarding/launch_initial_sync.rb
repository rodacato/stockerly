module Administration
  module UseCases
    module Onboarding
      # Kicks off the first fetch for whatever the wizard just seeded. It used
      # to also stamp `onboarded_at`, which is a User attribute and Identity's
      # to own — and stamping it here made the Welcome step unreachable, since
      # WelcomeController sends an onboarded user to the dashboard.
      class LaunchInitialSync < ApplicationUseCase
        def call(launch_sync: false)
          return Success({ launched: false }) unless launch_sync

          SyncPriorityAssetsJob.perform_later("stock", "high") if Asset.where(asset_type: :stock).exists?
          SyncPriorityAssetsJob.perform_later("crypto", "high") if Asset.where(asset_type: :crypto).exists?
          RefreshFxRatesJob.perform_later
          SyncMarketIndicesJob.perform_later

          Success({ launched: true })
        end
      end
    end
  end
end
