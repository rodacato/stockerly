class DoubleYahooFinanceDailyCeiling < ActiveRecord::Migration[8.1]
  # ProviderDefaults applies on create only. Same rule as RaiseYahooFinanceCeiling:
  # raise a lower ceiling, leave a higher one and NULL (unlimited) alone.
  DAILY = 4_000

  def up
    execute(<<~SQL.squish)
      UPDATE integrations
         SET daily_call_limit = #{DAILY}, updated_at = NOW()
       WHERE provider_name = 'Yahoo Finance'
         AND daily_call_limit IS NOT NULL
         AND daily_call_limit < #{DAILY}
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
