class AddCurrencyToAssets < ActiveRecord::Migration[8.1]
  ASSET_TYPE_CRYPTO = 1
  ASSET_TYPE_FIXED_INCOME = 4

  KNOWN_MXN_INDEX_SYMBOLS = %w[IPC].freeze
  KNOWN_USD_INDEX_SYMBOLS = %w[VIX SPX NDX DJI UKX].freeze

  def up
    add_column :assets, :currency, :string, limit: 3, default: "USD", null: false

    # Country-driven backfill: MXN candidates first, then explicit USD overrides.
    # See #41 discovery card and docs/sprints/2026-S02-truth-foundation/log.md
    # for the rule rationale (we trust country + asset_type, not symbol patterns).
    Asset.reset_column_information

    Asset.where(country: "MX")
         .or(Asset.where(asset_type: ASSET_TYPE_FIXED_INCOME))
         .or(Asset.where("symbol ILIKE 'CETE%'"))
         .or(Asset.where(symbol: KNOWN_MXN_INDEX_SYMBOLS))
         .update_all(currency: "MXN")

    Asset.where(country: "US")
         .or(Asset.where(asset_type: ASSET_TYPE_CRYPTO))
         .or(Asset.where(symbol: KNOWN_USD_INDEX_SYMBOLS))
         .update_all(currency: "USD")

    audit_unexpected_currency_assignments
  end

  def down
    remove_column :assets, :currency
  end

  private

  def audit_unexpected_currency_assignments
    suspects = Asset.where(currency: "USD")
                    .where("country IS NULL OR country <> 'US'")
                    .where.not(asset_type: ASSET_TYPE_CRYPTO)
                    .where.not(symbol: KNOWN_USD_INDEX_SYMBOLS)
                    .where("symbol NOT ILIKE 'CETE%'")
                    .pluck(:symbol, :asset_type, :country)

    return if suspects.empty?

    say "  ⚠ #{suspects.size} asset(s) defaulted to USD without a country=US/USA signal:"
    suspects.each { |sym, type, country| say "    - #{sym} (asset_type=#{type}, country=#{country.inspect})" }
    say "  Review manually and update via admin UI if needed."
  end
end
