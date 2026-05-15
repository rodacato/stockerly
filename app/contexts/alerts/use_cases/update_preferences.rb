module Alerts
  module UseCases
    # ADR-006: single mutation. Lets ActiveRecord::RecordInvalid propagate
    # so the controller can map it to 422 — no need to wrap a single
    # mechanical failure in a Result tuple.
    class UpdatePreferences < SimpleUseCase
      def call(user:, params:)
        # Build (not create!) for the new-preference path so `update!`
        # below performs a single INSERT instead of INSERT+UPDATE. For an
        # existing preference, `||=` short-circuits and update! is a
        # straight UPDATE — same single-write outcome.
        pref = user.alert_preference || user.build_alert_preference
        pref.update!(params.slice(:email_digest, :browser_push, :sms_notifications))
        pref
      end
    end
  end
end
