# Determines whether financial markets are currently open for trading.
# Used by sync jobs to skip API calls when markets are closed.
module MarketHours
  US_TIMEZONE  = "Eastern Time (US & Canada)"
  BMV_TIMEZONE = "America/Mexico_City"

  # Minutes since midnight, local to each market. 9:30 = 570, 16:00 = 960.
  US_SESSION  = (570...960)
  BMV_SESSION = (510...900)

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
    session_open?(US_TIMEZONE, US_SESSION)
  end

  # BMV: Mon-Fri 8:30 AM – 3:00 PM CST
  def self.bmv_market_open?
    session_open?(BMV_TIMEZONE, BMV_SESSION)
  end

  # Minutes elapsed since today's opening bell, or nil while the market is
  # closed. A monitor needs this to tell "the sync has not had its turn yet"
  # from "the sync is dead": at 9:31 both look like silence.
  def self.us_minutes_since_open
    minutes_since_open(US_TIMEZONE, US_SESSION)
  end

  def self.bmv_minutes_since_open
    minutes_since_open(BMV_TIMEZONE, BMV_SESSION)
  end

  # Crypto markets never close.
  def self.crypto_market_open?
    true
  end

  def self.session_open?(zone, session)
    now = Time.current.in_time_zone(zone)
    return false if now.saturday? || now.sunday?

    session.cover?(now.hour * 60 + now.min)
  end
  private_class_method :session_open?

  def self.minutes_since_open(zone, session)
    return nil unless session_open?(zone, session)

    now = Time.current.in_time_zone(zone)
    (now.hour * 60 + now.min) - session.first
  end
  private_class_method :minutes_since_open
end
