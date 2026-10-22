module Assistant
  module Domain
    # Where the question was asked: what the planner is told the screen shows,
    # and what the selector reads when the question does not say.
    module Screens
      DESCRIBED = {
        "panorama" => "Hoy: how the market and the user's holdings did today, and what is coming for them.",
        "senales" => "Señales: the indicator signals of the last week for what the user holds and watches.",
        "activos" => "Activos: the user's positions and watchlist.",
        "consolidado" => "Consolidado: the portfolio's value and return over time.",
        "reglas" => "Reglas: the user's alert rules.",
        "discover" => "Descubrir: market movers outside what the user follows.",
        "ajustes" => "Ajustes: settings."
      }.freeze

      READS = {
        "panorama" => [ [ "market.pulse", {} ], [ "portfolio.events", {} ] ],
        "senales" => [ [ "signals.recent", {} ] ],
        "activos" => [ [ "portfolio.positions", {} ] ],
        "consolidado" => [ [ "portfolio.positions", {} ] ]
      }.freeze

      def self.described(screen) = DESCRIBED[screen.to_s]

      def self.reads(screen) = READS.fetch(screen.to_s, [])
    end
  end
end
