# BMV + Banxico + NYSE/NASDAQ market holiday calendar.
#
# Source: BMV calendario oficial (https://www.bmv.com.mx/) + Banxico's own
# observed-holiday list. Banxico observes the same federal holidays as BMV
# but also closes for a couple of additional dates (e.g. Día de la Bandera
# is observed by Banxico but BMV typically trades a half-day).
#
# US source: the NYSE holiday calendar (https://www.nyse.com/markets/hours-calendars).
# NASDAQ observes the same closures, so both markets get the same list. Weekend
# holidays follow the exchange rule — Saturday observed the preceding Friday,
# Sunday the following Monday.
#
# Coverage: BMV and Banxico through 2026-12-25, NYSE and NASDAQ through
# 2027-12-24. MarketHours reads NYSE and BMV to gate its sessions, and a year
# with no rows here answers "no holidays" — so past the last date below every
# holiday reads as a trading day again and the monitor resumes alerting on
# them. CheckSyncHealthJob watches how far this file reaches and tells the
# owner a month before it runs out; that notice is the only thing standing
# between an un-updated calendar and a quiet wrong answer.
#
# Update annually before December — add the next year's dates as soon as each
# exchange publishes its calendar. Idempotent: re-running this seed is safe.

bmv_2026 = [
  [ "2026-01-01", "Año Nuevo" ],
  [ "2026-02-02", "Día de la Constitución" ],
  [ "2026-03-16", "Natalicio de Benito Juárez" ],
  [ "2026-04-02", "Jueves Santo" ],
  [ "2026-04-03", "Viernes Santo" ],
  [ "2026-05-01", "Día del Trabajo" ],
  [ "2026-09-16", "Día de la Independencia" ],
  [ "2026-11-02", "Día de Muertos (observado)" ],
  [ "2026-11-16", "Aniversario de la Revolución Mexicana (observado)" ],
  [ "2026-12-12", "Día de la Virgen de Guadalupe" ],
  [ "2026-12-25", "Navidad" ]
]

banxico_2026 = bmv_2026 + [
  [ "2026-02-05", "Día de la Constitución (Banxico fijo)" ],
  [ "2026-03-21", "Natalicio de Benito Juárez (Banxico fijo)" ],
  [ "2026-11-20", "Aniversario de la Revolución (Banxico fijo)" ]
]

us_2026 = [
  [ "2026-01-01", "New Year's Day" ],
  [ "2026-01-19", "Martin Luther King Jr. Day" ],
  [ "2026-02-16", "Washington's Birthday" ],
  [ "2026-04-03", "Good Friday" ],
  [ "2026-05-25", "Memorial Day" ],
  [ "2026-06-19", "Juneteenth National Independence Day" ],
  [ "2026-07-03", "Independence Day (observed)" ],
  [ "2026-09-07", "Labor Day" ],
  [ "2026-11-26", "Thanksgiving Day" ],
  [ "2026-12-25", "Christmas Day" ]
]

us_2027 = [
  [ "2027-01-01", "New Year's Day" ],
  [ "2027-01-18", "Martin Luther King Jr. Day" ],
  [ "2027-02-15", "Washington's Birthday" ],
  [ "2027-03-26", "Good Friday" ],
  [ "2027-05-31", "Memorial Day" ],
  [ "2027-06-18", "Juneteenth National Independence Day (observed)" ],
  [ "2027-07-05", "Independence Day (observed)" ],
  [ "2027-09-06", "Labor Day" ],
  [ "2027-11-25", "Thanksgiving Day" ],
  [ "2027-12-24", "Christmas Day (observed)" ]
]

us_calendar = us_2026 + us_2027

[ [ :BMV, bmv_2026 ], [ :Banxico, banxico_2026 ],
  [ :NYSE, us_calendar ], [ :NASDAQ, us_calendar ] ].each do |market, calendar|
  calendar.each do |date_str, name|
    MarketHoliday.find_or_create_by!(date: Date.parse(date_str), market: market) do |h|
      h.name = name
    end
  end
end

puts "Seeded #{MarketHoliday.count} market holidays (BMV + Banxico 2026, NYSE + NASDAQ 2026-2027)."
