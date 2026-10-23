module Trading
  module UseCases
    class UpdateTrade < ApplicationUseCase
      MAX_EDIT_AGE_DAYS = 30

      def call(user:, params:)
        attrs = yield validate(Trading::Contracts::UpdateTradeContract, params)
        attrs = blanks_as_unchanged(attrs)

        trade = Trade.find(attrs[:trade_id])
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio
        return Failure([ :unauthorized, "Not authorized to edit this trade" ]) unless trade.portfolio_id == portfolio.id
        return Failure([ :too_old, "Cannot edit trades older than #{MAX_EDIT_AGE_DAYS} days" ]) if too_old?(trade)

        previous_values = extract_previous(trade, attrs)
        return Failure([ :leaves_negative, "A later sale needs these shares" ]) unless update_and_resync(trade, attrs)

        publish(Events::TradeUpdated.new(
          trade_id: trade.id,
          user_id: user.id,
          position_id: trade.position_id || 0,
          changes: previous_values
        ))

        Success(trade)
      end

      private

      # Same rule as DeleteTrade: an edit that would leave a later sale without
      # its shares is undone whole.
      def update_and_resync(trade, attrs)
        committed = Trade.transaction do
          update_trade(trade, attrs)
          if position_affecting_change?(attrs)
            position = trade.position
            raise ActiveRecord::Rollback if position&.shares_from_trades&.negative?

            position&.resync_from_trades!
          end
          true
        end
        trade.reload unless committed
        committed
      end

      # The edit row posts every field; an emptied date means unchanged and an
      # emptied fee means no fee, never a NULL the column refuses.
      def blanks_as_unchanged(attrs)
        attrs = attrs.except(:executed_at) if attrs[:executed_at].blank?
        attrs = attrs.merge(fee: 0) if attrs.key?(:fee) && attrs[:fee].nil?
        attrs
      end

      def too_old?(trade)
        trade.executed_at < MAX_EDIT_AGE_DAYS.days.ago
      end

      def extract_previous(trade, attrs)
        changes = {}
        changes[:shares] = trade.shares.to_f if attrs.key?(:shares)
        changes[:price_per_share] = trade.price_per_share.to_f if attrs.key?(:price_per_share)
        changes[:fee] = trade.fee.to_f if attrs.key?(:fee)
        changes[:executed_at] = trade.executed_at.iso8601 if attrs.key?(:executed_at)
        changes
      end

      def update_trade(trade, attrs)
        updatable = attrs.slice(:shares, :price_per_share, :fee)
        updatable[:executed_at] = parse_executed_at(attrs[:executed_at]) if attrs.key?(:executed_at)
        updatable[:total_amount] = (updatable[:shares] || trade.shares) * (updatable[:price_per_share] || trade.price_per_share)
        trade.update!(updatable)
      end

      def position_affecting_change?(attrs)
        attrs.key?(:shares) || attrs.key?(:price_per_share)
      end

      def parse_executed_at(value)
        Time.zone.parse(value)
      rescue ArgumentError
        Time.current
      end
    end
  end
end
