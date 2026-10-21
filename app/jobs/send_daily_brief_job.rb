# R7: the morning summary pushed to the phone for whoever asked for it, so
# opening the app is optional. It says what Hoy would say, in Hoy's own words;
# a calm day is a message too, because "todo en orden" is the answer.
class SendDailyBriefJob < ApplicationJob
  include SyncLogging

  queue_as :default

  BODY_LIMIT = 140

  def perform
    sent = eligible_users.sum { |user| deliver(user) }

    log_sync_success("Daily Brief", message: "#{sent} install(s) reached")
  rescue StandardError => e
    log_sync_failure("Daily Brief", e.message)
    raise
  end

  private

  def eligible_users
    User.joins(:alert_preference).where(alert_preferences: { daily_push: true }).joins(:push_subscriptions).distinct
  end

  def deliver(user)
    data = Trading::UseCases::AssemblePanorama.call(user: user)
    today = data[:today]
    return 0 if today.state == :first_run

    Notifications::UseCases::PushDailyBrief.call(user: user, title: title_for(today), body: body_for(today, data))
  end

  def title_for(today)
    I18n.t("dashboard.hoy.veredicto.#{today.state}", count: today.total)
  end

  def body_for(today, data)
    helpers = ApplicationController.helpers
    lines = today.items.map { |item| helpers.hoy_item_title(item) }
    lines = [ helpers.hoy_subtitle(today.state, data[:vs_cetes], has_plan: data[:plan_status].present?) ].compact if lines.empty?

    lines.join(" · ").truncate(BODY_LIMIT)
  end
end
