# Collects infrastructure health metrics from Solid Queue, Solid Cache,
# and SystemLog (circuit breaker events).
#
# Solid Queue / Solid Cache queries use savepoints so a table-missing
# error in test/dev does not poison the surrounding transaction.
class HealthMetrics
  class << self
    # --- Job Queue Metrics (Solid Queue) ---

    def queue_depth
      safe_queue_query { SolidQueue::ReadyExecution.count }
    end

    def in_progress_jobs
      safe_queue_query { SolidQueue::ClaimedExecution.count }
    end

    def failed_jobs
      safe_queue_query { SolidQueue::FailedExecution.count }
    end

    def scheduled_jobs
      safe_queue_query { SolidQueue::ScheduledExecution.count }
    end

    def queue_workers
      safe_queue_query { SolidQueue::Process.count }
    end

    # --- Cache Metrics (Solid Cache) ---

    def cache_entries
      safe_cache_query { SolidCache::Entry.count }
    end

    def cache_byte_size
      safe_cache_query { SolidCache::Entry.sum(:byte_size) }
    end

    # --- Circuit Breaker Metrics (SystemLog) ---

    def circuit_breaker_events(since: 24.hours.ago)
      SystemLog.by_module("resilience")
               .where("created_at >= ?", since)
               .recent
               .limit(10)
    end

    def open_circuits_count(since: 24.hours.ago)
      SystemLog.by_module("resilience")
               .where("created_at >= ?", since)
               .where(severity: :warning)
               .select(:task_name)
               .distinct
               .count
    end

    private

    def safe_queue_query(&block)
      SolidQueue::Record.transaction(requires_new: true, &block)
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
      nil
    end

    def safe_cache_query(&block)
      SolidCache::Record.transaction(requires_new: true, &block)
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
      nil
    end
  end
end
