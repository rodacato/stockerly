# Daily cleanup of expired invite codes.
#
# We don't DELETE — just write a SystemLog entry so we keep audit history of
# who created which codes and when they expired. The `unused + expires_at < now`
# state is sufficient to mark a code as unredeemable (see InviteCode#redeemable?
# and Register use case), so cleanup here is a no-op operationally; the value
# is the audit trail + a hook to alert on stale invites that never got used
# (signal that nobody is reaching the registration link).
class CleanupExpiredInviteCodesJob < ApplicationJob
  queue_as :default

  CYCLE_WINDOW = 24.hours

  def perform
    expired_count = InviteCode.unused.where(expires_at: CYCLE_WINDOW.ago..Time.current).count
    return if expired_count.zero?

    SystemLog.create!(
      task_name: "InviteCode Cleanup",
      module_name: "identity",
      severity: :success,
      error_message: "#{expired_count} invite code(s) expired without being redeemed in the last #{CYCLE_WINDOW.inspect}"
    )
  end
end
