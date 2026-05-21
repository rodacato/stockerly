# Daily evaluation pass for calendar-driven alert rules. Price/RSI/volume
# alerts fire reactively on Market Data price events; this job covers the
# rules whose trigger depends on a calendar date — currently just
# dividend_ex_date.
#
# Schedule via Solid Queue recurring jobs (config/recurring.yml). Idempotent:
# AlertRule#cooldown_minutes prevents duplicate firings on the same window.
class EvaluateDateBasedAlertsJob < ApplicationJob
  queue_as :default

  def perform
    Alerts::UseCases::EvaluateDateBasedRules.new.call
  end
end
