module Alerts
  module Domain
    # es-MX copy for a rule that just fired. ADR-0001: state what happened and
    # where it came from; never suggest what to do about it.
    #
    # The title carries the fact, the body carries the provenance — they never
    # restate each other, and a price is never rendered without its currency.
    class TriggerNotice
      FALLBACK_TITLE = "Una de tus reglas se disparó".freeze

      def initialize(rule:, asset_symbol:, price: nil)
        @rule   = rule
        @symbol = asset_symbol
        @price  = price
      end

      def title
        return FALLBACK_TITLE unless @rule
        return happening if @rule.marketwide?

        [ @symbol, happening ].compact_blank.join(" ")
      end

      def body
        return "Revísala en tu bandeja." unless @rule

        [ trigger_price, cooldown ].compact_blank.join(" · ")
      end

      private

      def happening
        case @rule.condition
        when "price_crosses_above" then "cruzó #{money(@rule.threshold_value)} al alza"
        when "price_crosses_below" then "cruzó #{money(@rule.threshold_value)} a la baja"
        when "day_change_percent"  then "se movió más de #{threshold}% en el día"
        when "rsi_overbought"      then "entró en zona de sobrecompra (RSI(14) ≥ #{threshold})"
        when "rsi_oversold"        then "entró en zona de sobreventa (RSI(14) ≤ #{threshold})"
        when "volume_spike"        then "operó con volumen #{threshold}× arriba de su promedio"
        when "dividend_ex_date"    then "se acerca a su fecha ex-dividendo"
        when "bmv_holiday"         then "La BMV cierra por día festivo"
        when "cete_auction"        then "Banxico publicó una nueva subasta de CETES"
        else                            "cumplió una de tus reglas"
        end
      end

      def trigger_price
        return nil if @price.blank?

        "Al disparo: #{money(@price)}"
      end

      def cooldown
        minutes = @rule.cooldown_minutes.to_i
        return nil unless minutes.positive?

        "no vuelve a avisarte en #{minutes} min"
      end

      def threshold
        ActiveSupport::NumberHelper.number_to_rounded(
          @rule.threshold_value.to_d, precision: 2, strip_insignificant_zeros: true
        )
      end

      def money(value)
        amount = ActiveSupport::NumberHelper.number_to_rounded(
          value.to_d, precision: 2, delimiter: ","
        )
        "#{@rule.currency} #{amount}"
      end
    end
  end
end
