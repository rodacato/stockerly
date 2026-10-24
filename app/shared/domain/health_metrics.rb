# Collects infrastructure health metrics from Solid Queue and Solid Cache.
#
# Solid Queue / Solid Cache queries use savepoints so a table-missing
# error in test/dev does not poison the surrounding transaction.
class HealthMetrics
  class << self
    # --- Job Queue Metrics (Solid Queue) ---

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

    # nil means the queue could not be read at all, which is no more attended
    # than a queue with no worker in it.
    def queue_attended?
      queue_workers.to_i.positive?
    end

    # --- Cache Metrics (Solid Cache) ---

    def cache_entries
      safe_cache_query { SolidCache::Entry.count }
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
