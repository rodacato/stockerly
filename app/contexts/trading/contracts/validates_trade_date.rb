module Trading
  module Contracts
    # The trade sheet's executed_at guard, shared by the contract that creates a
    # trade and the one that edits it — an edit that could set a date the create
    # would refuse is the same field with two answers. The importer keeps its
    # own: its field is required, and its findings are read as a row report in
    # English rather than as a flash.
    module ValidatesTradeDate
      def self.included(contract)
        contract.rule(:executed_at) do
          next if value.blank?

          case Trading::Domain::TradeDate.fault(value)
          when :invalid then key.failure(I18n.t("trades.errores.fecha_invalida"))
          when :future  then key.failure(I18n.t("trades.errores.fecha_futura"))
          end
        end
      end
    end
  end
end
