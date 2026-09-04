module Administration
  module UseCases
    module Onboarding
      # Kicks off the first fetch for whatever the wizard just seeded. It used
      # to also stamp `onboarded_at`, which is a User attribute and Identity's
      # to own — and stamping it here made the Welcome step unreachable, since
      # WelcomeController sends an onboarded user to the dashboard.
      class LaunchInitialSync < SimpleUseCase
        def call(launch_sync: false)
          return { launched: false } unless launch_sync

          SyncPriorityAssetsJob.perform_later("stock", "high") if Asset.exists?(asset_type: :stock)
          SyncPriorityAssetsJob.perform_later("crypto", "high") if Asset.exists?(asset_type: :crypto)
          RefreshFxRatesJob.perform_later
          SyncMarketIndicesJob.perform_later

          { launched: true }
        end
      end
    end
  end
end
