# D17: `auto_sync_enabled` was written by the settings screen and read by
# nothing. It guards the jobs that go out to the network for market data —
# what consumes provider quota and what pausing is actually for.
#
# Local computation (trend scores, observation detection, snapshots) keeps
# running: with no new data it is a no-op, and stopping it would make the
# switch mean something wider than its label.
#
# Defaults to on, so an instance that predates the wiring does not go quiet.
module PausableSync
  extend ActiveSupport::Concern

  KEY = "auto_sync_enabled".freeze

  included do
    around_perform do |job, block|
      if SiteConfig.enabled?(KEY, default: true)
        block.call
      else
        Rails.logger.info("[PausableSync] #{job.class.name} skipped: #{KEY} is off")
      end
    end
  end
end
