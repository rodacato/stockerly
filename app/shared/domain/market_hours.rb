# Determines whether financial markets are currently open for trading.
# Used by sync jobs to skip API calls when markets are closed, and by the
# freshness monitor to decide whether silence can be read as failure at all.
#
# Holidays are part of that answer (#504). Without them a monitor gated on
# "the session is underway" believes the NYSE trades on Thanksgiving, sees
# prices that are legitimately a day old, and tells the owner his US stocks
# stopped updating — roughly nine or ten days a year, per market.
#
# What the calendar cannot express: a half day. `market_holidays` carries a
# date and a market, with no session times, so the NYSE's 13:00 closes on
# Black Friday and Christmas Eve read here as full trading days. Deliberate:
# the error is bounded at three hours against a six-hour owner threshold, so
# it cannot produce a false alarm, and inventing session times in the schema
# to shave an operator-side artifact is not worth the migration.
module MarketHours
  US_TIMEZONE  = "Eastern Time (US & Canada)"
  BMV_TIMEZONE = "America/Mexico_City"

  # Minutes since midnight, local to each market. 9:30 = 570, 16:00 = 960.
  US_SESSION  = (570...960)
  BMV_SESSION = (510...900)

  US_EXCHANGES  = %w[NYSE NASDAQ].freeze
  BMV_EXCHANGES = %w[BMV].freeze

  # The one place a session maps to a holiday calendar. MarketHoliday keeps a
  # row per exchange and the two US exchanges observe the same closures — the
  # seed writes one list to both — so a single session asks a single calendar.
  # Should NASDAQ ever diverge, the seed splits and this constant is where the
  # split becomes visible.
  HOLIDAY_CALENDARS = { us: :NYSE, bmv: :BMV }.freeze

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

  # NYSE/NASDAQ: Mon-Fri 9:30 AM – 4:00 PM ET, minus the exchange's holidays
  def self.us_market_open?
    session_open?(:us, US_TIMEZONE, US_SESSION)
  end

  # BMV: Mon-Fri 8:30 AM – 3:00 PM CST, minus the exchange's holidays
  def self.bmv_market_open?
    session_open?(:bmv, BMV_TIMEZONE, BMV_SESSION)
  end

  # Minutes elapsed since today's opening bell, or nil while the market is
  # closed. A monitor needs this to tell "the sync has not had its turn yet"
  # from "the sync is dead": at 9:31 both look like silence.
  def self.us_minutes_since_open
    minutes_since_open(:us, US_TIMEZONE, US_SESSION)
  end

  def self.bmv_minutes_since_open
    minutes_since_open(:bmv, BMV_TIMEZONE, BMV_SESSION)
  end

  # Crypto markets never close.
  def self.crypto_market_open?
    true
  end

  # A year the calendar does not reach answers "no holidays", so an exhausted
  # calendar degrades to the weekday-only behaviour this file had before —
  # syncs keep running rather than silently pausing for a year. That failure
  # is quiet by construction, which is why CheckSyncHealthJob watches how far
  # the calendar reaches and says so while there is still time to reseed.
  def self.holiday?(market, date)
    MarketData::Queries::MarketCalendar
      .dates_in_year(market: HOLIDAY_CALENDARS.fetch(market), year: date.year)
      .include?(date)
  end

  # The weekday and clock tests come first so the calendar is only read during
  # the session itself — measured at 0.200 ms against 0.007 ms for the
  # arithmetic, which is why there is no cache here to keep coherent.
  def self.session_open?(market, zone, session)
    now = Time.current.in_time_zone(zone)
    return false if now.saturday? || now.sunday?
    return false unless session.cover?((now.hour * 60) + now.min)

    !holiday?(market, now.to_date)
  end
  private_class_method :session_open?

  def self.minutes_since_open(market, zone, session)
    return nil unless session_open?(market, zone, session)

    now = Time.current.in_time_zone(zone)
    ((now.hour * 60) + now.min) - session.first
  end
  private_class_method :minutes_since_open
end
