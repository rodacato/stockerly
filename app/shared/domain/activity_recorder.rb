# Single entry point for recording user activity. Every UserActivity row
# in the database is created through this class — controllers, event
# handlers, and any future plug-in caller must go through `.call`.
#
# Recording is synchronous: a single indexed insert per HTML page load
# (and per wired domain event) is cheaper than enqueuing through Solid
# Queue for a closed-beta workload (~20 users). If activity volume ever
# grows, swap the body of `.call` for `RecordActivityJob.perform_later`
# without touching any caller.
class ActivityRecorder
  def self.call(user:, action:, params: {})
    return nil if user.nil?

    UserActivity.create!(
      user:        user,
      action:      action.to_s,
      params:      params || {},
      occurred_at: Time.current
    )
  rescue ActiveRecord::ActiveRecordError => e
    # Recording activity must never break the user's request or the
    # event-handling chain. Log + swallow.
    Rails.logger.error("[ActivityRecorder] failed: #{e.class}: #{e.message}")
    nil
  end
end
