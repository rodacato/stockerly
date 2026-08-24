module Trading
  module Handlers
    # A trade dated before today invalidates every snapshot from its date
    # onward — whether it was recorded, edited or discarded, since all three
    # change what that day held. Editing and deleting are capped at 30 days,
    # but inside that window the damage is identical.
    #
    # Runs async so capture stays inside the JTBD #5 budget; the history is a
    # background concern, the form is not.
    class RebuildSnapshotsOnBackdatedTrade
      def self.async? = true

      def self.call(event)
        trade_id = event.is_a?(Hash) ? event[:trade_id] : event.trade_id
        # A discarded trade is still found here; HistoricalValuation reads
        # `kept`, so the rebuild sees the portfolio without it.
        trade = Trade.find_by(id: trade_id)
        return if trade.nil?

        executed_on = trade.executed_at.to_date
        return if executed_on >= Date.current

        Trading::UseCases::RebuildSnapshots.call(portfolio: trade.portfolio, from: executed_on)
      end
    end
  end
end
