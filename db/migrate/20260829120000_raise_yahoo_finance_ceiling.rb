class RaiseYahooFinanceCeiling < ActiveRecord::Migration[8.1]
  # ProviderDefaults applies on create only, so raising the constant leaves
  # every existing instance throttled to whatever it was seeded with -- and
  # what that is varies: this repo's own dev row holds 5/min and no daily cap,
  # not the 6/200 the defaults file states.
  #
  # So this raises rather than replaces. A ceiling already above the new one is
  # left alone, and NULL is left alone because NULL reads as unlimited here.
  MINUTE = 30
  DAILY = 2_000

  def up
    raise_ceiling("max_requests_per_minute", MINUTE)
    raise_ceiling("daily_call_limit", DAILY)
  end

  # Irreversible because the old pair is not recoverable: the value each column
  # held before differs per instance, and this migration only knows it was lower.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def raise_ceiling(column, ceiling)
    execute(<<~SQL)
      UPDATE integrations
         SET #{column} = #{ceiling}, updated_at = NOW()
       WHERE provider_name = 'Yahoo Finance'
         AND #{column} IS NOT NULL
         AND #{column} < #{ceiling}
    SQL
  end
end
