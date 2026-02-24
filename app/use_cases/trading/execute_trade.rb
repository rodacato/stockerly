module Trading
  class ExecuteTrade < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Trading::ExecuteTradeContract, params)
      portfolio = user.portfolio
      return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

      asset = Asset.find_by!(symbol: attrs[:asset_symbol].upcase)
      position = find_or_create_position(portfolio, asset, attrs)

      return Failure([ :insufficient_shares, "Not enough shares to sell" ]) if sell_exceeds_position?(attrs, position)

      trade = persist_trade(portfolio, asset, position, attrs)
      update_position_after_trade(position, attrs)

      publish(TradeExecuted.new(
        trade_id: trade.id,
        user_id: user.id,
        position_id: position.id,
        side: attrs[:side],
        shares: attrs[:shares].to_s
      ))

      Success(trade)
    end

    private

    def find_or_create_position(portfolio, asset, attrs)
      existing = portfolio.positions.find_by(asset: asset, status: :open)
      return existing if existing
      return nil if attrs[:side] == "sell"

      portfolio.positions.create!(
        asset: asset,
        shares: 0,
        avg_cost: attrs[:price_per_share],
        currency: "USD",
        opened_at: Time.current,
        status: :open
      )
    end

    def sell_exceeds_position?(attrs, position)
      return true if attrs[:side] == "sell" && position.nil?
      return true if attrs[:side] == "sell" && attrs[:shares] > position.shares

      false
    end

    def persist_trade(portfolio, asset, position, attrs)
      portfolio.trades.create!(
        asset: asset,
        position: position,
        side: attrs[:side],
        shares: attrs[:shares],
        price_per_share: attrs[:price_per_share],
        fee: attrs[:fee] || 0,
        currency: position&.currency || "USD",
        executed_at: parse_executed_at(attrs[:executed_at])
      )
    end

    def update_position_after_trade(position, attrs)
      return unless position

      if attrs[:side] == "buy"
        position.update!(shares: position.shares + attrs[:shares])
      elsif attrs[:side] == "sell"
        remaining = position.shares - attrs[:shares]
        if remaining.zero?
          position.update!(status: :closed, shares: remaining, closed_at: Time.current)
        else
          position.update!(shares: remaining)
        end
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
