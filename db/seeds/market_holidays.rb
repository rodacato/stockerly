# BMV + Banxico market holiday calendar.
#
# Source: BMV calendario oficial (https://www.bmv.com.mx/) + Banxico's own
# observed-holiday list. Banxico observes the same federal holidays as BMV
# but also closes for a couple of additional dates (e.g. Día de la Bandera
# is observed by Banxico but BMV typically trades a half-day).
#
# Update annually before December — add the next year's dates as soon as the
# BMV publishes its calendar. Idempotent: re-running this seed is safe.

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

[ [ :BMV, bmv_2026 ], [ :Banxico, banxico_2026 ] ].each do |market, calendar|
  calendar.each do |date_str, name|
    MarketHoliday.find_or_create_by!(date: Date.parse(date_str), market: market) do |h|
      h.name = name
    end
  end
end

puts "Seeded #{MarketHoliday.count} market holidays (BMV + Banxico, 2026)."
