# One row per (day, path): how many times a screen was opened that day.
class AppOpen < ApplicationRecord
  validates :day, :path, presence: true
  validates :count, numericality: { greater_than_or_equal_to: 0 }

  def self.record(path:, day: Time.zone.today)
    upsert( # rubocop:disable Rails/SkipsModelValidations -- typed values, atomic increment
      { day:, path:, count: 1 },
      unique_by: %i[day path],
      on_duplicate: Arel.sql("count = app_opens.count + 1, updated_at = NOW()"),
      record_timestamps: true
    )
  end

  # Oldest first, one entry per day, zero where the screen was not opened.
  def self.per_day(path:, days: 14, today: Time.zone.today)
    since  = today - (days - 1)
    counts = where(path:, day: since..today).pluck(:day, :count).to_h

    (since..today).map { |day| [ day, counts.fetch(day, 0) ] }
  end

  # Opens across every path that starts with `prefix` (the ? helps live under
  # "help:<figure>"), over the last `days` days.
  def self.total(prefix:, days: 7, today: Time.zone.today)
    where("path LIKE ?", "#{sanitize_sql_like(prefix)}%").where(day: (today - (days - 1))..today).sum(:count)
  end
end
