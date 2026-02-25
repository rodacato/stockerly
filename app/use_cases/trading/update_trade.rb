module Trading
  class UpdateTrade < ApplicationUseCase
    MAX_EDIT_AGE_DAYS = 30

    def call(user:, params:)
      attrs = yield validate(Trading::UpdateTradeContract, params)

      trade = Trade.find(attrs[:trade_id])
      portfolio = user.portfolio
      return Failure([ :not_found, "Portfolio not found" ]) unless portfolio
      return Failure([ :unauthorized, "Not authorized to edit this trade" ]) unless trade.portfolio_id == portfolio.id
      return Failure([ :too_old, "Cannot edit trades older than #{MAX_EDIT_AGE_DAYS} days" ]) if too_old?(trade)

      previous_values = extract_previous(trade, attrs)
      update_trade(trade, attrs)
      recalculate_position(trade.position) if position_affecting_change?(attrs)

      publish(TradeUpdated.new(
        trade_id: trade.id,
        user_id: user.id,
        position_id: trade.position_id || 0,
        changes: previous_values
      ))

      Success(trade)
    end

    private

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

    def recalculate_position(position)
      return unless position

      position.recalculate_avg_cost!

      remaining = position.trades.where(side: :buy).sum(:shares) - position.trades.where(side: :sell).sum(:shares)
      if remaining.zero?
        position.update!(status: :closed, shares: remaining, closed_at: Time.current)
      else
        position.update!(shares: remaining, status: :open, closed_at: nil)
      end
    end

    def parse_executed_at(value)
      return Time.current if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError
      Time.current
    end
  end
end
