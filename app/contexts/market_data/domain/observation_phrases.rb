module MarketData
  module Domain
    # The es-MX phrase for each persisted observation type (ADR-001: describes, never advises).
    module ObservationPhrases
      PHRASES = {
        "rsi_oversold_entered"   => "entró en zona de sobreventa (RSI(14) por debajo de 30)",
        "rsi_overbought_entered" => "entró en zona de sobrecompra (RSI(14) por encima de 70)",
        "rsi_oversold_exited"    => "salió de la zona de sobreventa",
        "rsi_overbought_exited"  => "salió de la zona de sobrecompra",
        "ma200_crossed_above"    => "cruzó al alza su MA200",
        "ma200_crossed_below"    => "cruzó a la baja su MA200",
        "ma50_crossed_above"     => "cruzó al alza su MA50",
        "ma50_crossed_below"     => "cruzó a la baja su MA50",
        "bb_upper_breached"      => "rompió la banda de Bollinger superior",
        "bb_lower_breached"      => "rompió la banda de Bollinger inferior"
      }.freeze

      def self.for(type) = PHRASES.fetch(type, type.humanize)
    end
  end
end
