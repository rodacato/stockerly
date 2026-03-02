module Trading
  module UseCases
    class DeleteTrade < ApplicationUseCase
      MAX_DELETE_AGE_DAYS = 30

      def call(user:, trade_id:)
        trade = Trade.find_by(id: trade_id)
        return Failure([ :not_found, "Trade not found" ]) unless trade

        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio
        return Failure([ :unauthorized, "Not authorized to delete this trade" ]) unless trade.portfolio_id == portfolio.id
        return Failure([ :already_discarded, "Trade already deleted" ]) if trade.discarded?
        return Failure([ :too_old, "Cannot delete trades older than #{MAX_DELETE_AGE_DAYS} days" ]) if too_old?(trade)

        trade.discard!
        recalculate_position(trade.position)

        publish(Events::TradeDeleted.new(
          trade_id: trade.id,
          user_id: user.id,
          position_id: trade.position_id || 0
        ))

        Success(trade)
      end

      private

      def too_old?(trade)
        trade.executed_at < MAX_DELETE_AGE_DAYS.days.ago
      end

      def recalculate_position(position)
        return unless position

        position.recalculate_avg_cost!

        remaining = position.trades.kept.where(side: :buy).sum(:shares) - position.trades.kept.where(side: :sell).sum(:shares)
        if remaining.zero?
          position.update!(status: :closed, shares: remaining, closed_at: Time.current)
        else
          position.update!(shares: remaining, status: :open, closed_at: nil)
        end
      end
    end
  end
end
