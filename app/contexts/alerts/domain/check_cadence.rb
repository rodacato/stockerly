require "fugit"

module Alerts
  module Domain
    # When a rule is evaluated, read from the recurring schedule so the screen
    # never states a cadence the jobs do not run.
    class CheckCadence
      Cadence = Data.define(:kind, :minutes, :time)

      SCHEDULE_FILE = "config/recurring.yml".freeze
      PRICE_SYNC_JOB = "SyncPriorityAssetsJob".freeze
      DATE_JOB = "EvaluateDateBasedAlertsJob".freeze

      def self.for(rule)
        rule.date_based? ? daily : on_price_update
      end

      def self.on_price_update
        seconds = tasks_for(PRICE_SYNC_JOB).filter_map { |task| frequency(task) }.min
        Cadence.new(kind: :price_update, minutes: seconds&.div(60), time: nil)
      end

      def self.daily
        cron = tasks_for(DATE_JOB).filter_map { |task| Fugit.parse(task["schedule"]) }.first
        time = cron && format("%d:%02d", cron.hours.first, cron.minutes.first)
        Cadence.new(kind: :daily, minutes: nil, time: time)
      end

      def self.tasks_for(job_class)
        schedule.values.select { |task| task["class"] == job_class }
      end

      def self.frequency(task)
        Fugit.parse(task["schedule"])&.rough_frequency
      end

      def self.schedule
        @schedule ||= YAML.load_file(Rails.root.join(SCHEDULE_FILE)).fetch("production")
      end

      private_class_method :tasks_for, :frequency, :schedule
    end
  end
end
