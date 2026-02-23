# Determines whether financial markets are currently open for trading.
# Used by sync jobs to skip API calls when markets are closed.
module MarketHours
  US_TIMEZONE  = "Eastern Time (US & Canada)"
  BMV_TIMEZONE = "America/Mexico_City"

  US_EXCHANGES  = %w[NYSE NASDAQ].freeze
  BMV_EXCHANGES = %w[BMV].freeze

  # Generic entry point: is the market open for a given exchange?
  def self.open?(exchange)
    return true if exchange.blank?

    if US_EXCHANGES.include?(exchange.upcase)
      us_market_open?
    elsif BMV_EXCHANGES.include?(exchange.upcase)
      bmv_market_open?
    else
      true # Unknown exchanges default to open (don't skip sync)
    end
  end

  # Convenience: determine market status from an asset's attributes.
  def self.open_for_asset?(asset)
    return true if asset.asset_type_crypto?

    open?(asset.exchange)
  end

  # NYSE/NASDAQ: Mon-Fri 9:30 AM – 4:00 PM ET
  def self.us_market_open?
    now = Time.current.in_time_zone(US_TIMEZONE)
    return false if now.saturday? || now.sunday?

    minutes_since_midnight = now.hour * 60 + now.min
    minutes_since_midnight >= 570 && minutes_since_midnight < 960 # 9:30=570, 16:00=960
  end

  # BMV: Mon-Fri 8:30 AM – 3:00 PM CST
  def self.bmv_market_open?
    now = Time.current.in_time_zone(BMV_TIMEZONE)
    return false if now.saturday? || now.sunday?

    minutes_since_midnight = now.hour * 60 + now.min
    minutes_since_midnight >= 510 && minutes_since_midnight < 900 # 8:30=510, 15:00=900
  end

  # Crypto markets never close.
  def self.crypto_market_open?
    true
  end
end
