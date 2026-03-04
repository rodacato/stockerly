module Administration
  module UseCases
    module Dashboard
      class LoadHealthMetrics < ApplicationUseCase
        def call
          Success({
            queue_depth: HealthMetrics.queue_depth,
            in_progress_jobs: HealthMetrics.in_progress_jobs,
            failed_jobs: HealthMetrics.failed_jobs,
            scheduled_jobs: HealthMetrics.scheduled_jobs,
            queue_workers: HealthMetrics.queue_workers,
            cache_entries: HealthMetrics.cache_entries,
            cache_byte_size: HealthMetrics.cache_byte_size,
            circuit_breaker_events: HealthMetrics.circuit_breaker_events,
            open_circuits_count: HealthMetrics.open_circuits_count
          })
        end
      end
    end
  end
end
