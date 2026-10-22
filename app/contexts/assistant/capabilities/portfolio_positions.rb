module Assistant
  module Capabilities
    # What the owner holds, valued as Activos values it: the screen's figures, never recomputed.
    class PortfolioPositions < Capability
      MAX_CHARS = 1_200
      LISTED = 10

      declare "portfolio.positions", optional: %i[symbol], holdings: true,
                                     description: "The user's own portfolio as Stockerly values it: total value, cost and unrealised gain " \
                                                  "in the user's currency, and each open position's value, share of the total and gain. " \
                                                  "With a symbol, only that position, with its shares, cost and how much of the gain came " \
                                                  "from the asset and how much from the exchange rate."

      def cards(symbol: nil)
        data = Trading::Queries::Holdings.call
        return [] unless data
        return [ total_card(data), list_card(data) ] if symbol.blank?

        held = data[:positions].find { |position| [ position[:symbol], InstrumentLabel.short(position[:symbol]) ].map(&:upcase).include?(symbol) }
        held ? [ position_card(held, data) ] : []
      end

      private

      def total_card(data)
        total = data[:total]
        currency = data[:currency]
        lines = [ I18n.t("assistant.cards.costo", amount: amount(total[:cost], currency)),
                  I18n.t("assistant.cards.ganancia", amount: signed(total[:gain], currency), percent: helpers.signed_percent(total[:gain_percent])) ]
        lines << I18n.t("assistant.cards.hoy", amount: signed(total[:day_gain], currency), percent: helpers.signed_percent(total[:day_gain_percent])) if total[:day_gain]
        lines << I18n.t("assistant.cards.posiciones", count: data[:positions].size)
        card(kind: "portfolio", title: I18n.t("assistant.cards.tu_portafolio"), figure: amount(total[:value], currency),
             body: lines.join(" · "), source: prices_as_of(data))
      end

      def list_card(data)
        listed, rest = data[:positions].partition.with_index { |_, index| index < LISTED }
        lines = listed.map do |position|
          share = position[:share_percent] && helpers.unsigned_percent(position[:share_percent])
          "#{InstrumentLabel.short(position[:symbol])} #{amount(position[:value], data[:currency])} (#{share}) #{helpers.signed_percent(position[:gain_percent])}"
        end
        lines << I18n.t("assistant.cards.y_mas", count: rest.size) if rest.any?
        card(kind: "positions", title: I18n.t("assistant.cards.tus_posiciones"), body: lines.join(" · "), source: prices_as_of(data))
      end

      def position_card(position, data)
        currency = data[:currency]
        lines = [ I18n.t("assistant.cards.titulos", shares: helpers.format_shares(position[:shares])),
                  I18n.t("assistant.cards.costo", amount: amount(position[:cost], currency)),
                  I18n.t("assistant.cards.ganancia", amount: signed(position[:gain], currency), percent: helpers.signed_percent(position[:gain_percent])),
                  I18n.t("assistant.cards.por_el_activo", amount: signed(position[:from_asset], currency)),
                  I18n.t("assistant.cards.por_el_tipo_de_cambio", amount: signed(position[:from_fx], currency)) ]
        lines << I18n.t("assistant.cards.del_portafolio", percent: helpers.unsigned_percent(position[:share_percent])) if position[:share_percent]
        lines << I18n.t("assistant.cards.vence", date: long_date(position[:maturity_date])) if position[:maturity_date]
        card(kind: "position", title: I18n.t("assistant.cards.tu_posicion", label: InstrumentLabel.name(position[:symbol], position[:name])),
             figure: amount(position[:value], currency), body: lines.join(" · "), source: prices_as_of(data))
      end

      def amount(value, currency) = helpers.format_currency_mx(value, currency: currency)

      def signed(value, currency) = helpers.signed_currency_mx(value, currency: currency)

      def prices_as_of(data) = data[:prices_as_of] && I18n.t("assistant.cards.precios_al", date: long_date(data[:prices_as_of]))
    end
  end
end
