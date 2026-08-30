module Trading
  module UseCases
    class ExecuteTrade < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Trading::Contracts::ExecuteTradeContract, params)
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        asset = Asset.find_by!(symbol: attrs[:asset_symbol].upcase)
        trade_currency = attrs[:currency] || asset.currency
        fx_rate = yield capture_fx(trade_currency, attrs)
        return Failure([ :missing_fx_rate, trade_currency ]) if unpriceable?(trade_currency, asset, fx_rate)

        position = find_or_create_position(portfolio, asset, attrs)
        return Failure([ :insufficient_shares, "Not enough shares to sell" ]) if sell_exceeds_position?(attrs, position)

        trade = persist_trade(portfolio, asset, position, attrs, trade_currency, fx_rate)
        update_position_after_trade(position, attrs)

        publish(Events::TradeExecuted.new(
          trade_id: trade.id,
          user_id: user.id,
          position_id: position.id,
          side: attrs[:side],
          shares: attrs[:shares].to_s
        ))

        Success(trade)
      end

      private

      # Against MXN, never against the user's current preference: a rate stored
      # relative to a setting stops being true the moment the setting changes,
      # and the backfill could not repair it because the column was not null.
      #
      # A missing rate stores NULL instead of refusing the trade. NULL is true —
      # it says "not known yet" — and `fx_rate_backfill:trades` fills it at the
      # trade's own date once the series syncs. Refusing would mean a fresh
      # instance, whose FX history has not run yet, could not record anything at
      # all. The read path still fails loud rather than valuing NULL at 1:1.
      def capture_fx(currency, attrs)
        Success(Trading::Domain::ExecutionRate.capture(
          currency: currency,
          at_date: attrs[:executed_at]&.to_date,
          override: attrs[:fx_rate_at_execution]
        ))
      end

      # capture_fx stores NULL when the rate is not known yet and the backfill
      # repairs it, but only a same-currency trade has a cost basis without it.
      def unpriceable?(currency, asset, fx_rate)
        fx_rate.nil? && currency != asset.currency
      end

      def find_or_create_position(portfolio, asset, attrs)
        return create_new_position(portfolio, asset, attrs) if always_new_lot?(asset, attrs)

        existing = portfolio.positions.find_by(asset: asset, status: :open)
        return existing if existing
        return nil if attrs[:side] == "sell"

        create_new_position(portfolio, asset, attrs)
      end

      # Fixed-income buys NEVER merge into an existing open position — each
      # purchase is a distinct lot with its own maturity_date (#29 JTBD #3).
      # The asset symbol rolls (CETES_28D maturing on Jun 15 and CETES_28D
      # maturing on Jul 29 share a symbol but are independent lots), so the
      # default merge-by-asset rule from equities would silently collapse
      # them and discard the second maturity. Sells of fixed-income are
      # left on the merge path because they're rare in practice and the
      # lot-selection question (FIFO vs explicit) is out of #29 scope.
      def always_new_lot?(asset, attrs)
        attrs[:side] == "buy" && asset.asset_type_fixed_income?
      end

      def create_new_position(portfolio, asset, attrs)
        portfolio.positions.create!(
          asset: asset,
          shares: 0,
          avg_cost: attrs[:price_per_share],
          opened_at: Time.current,
          status: :open,
          maturity_date: maturity_date_for(asset, attrs)
        )
      end

      # Per-lot maturity for fixed-income positions only (#29 JTBD #3). The
      # contract requires the field when the asset is fixed_income; for
      # other asset types the value is ignored even if supplied.
      def maturity_date_for(asset, attrs)
        return nil unless asset.asset_type_fixed_income?
        return nil if attrs[:maturity_date].blank?

        Date.parse(attrs[:maturity_date])
      rescue ArgumentError, TypeError
        nil
      end

      def sell_exceeds_position?(attrs, position)
        return true if attrs[:side] == "sell" && position.nil?
        return true if attrs[:side] == "sell" && attrs[:shares] > position.shares

        false
      end

      def persist_trade(portfolio, asset, position, attrs, currency, fx_rate)
        portfolio.trades.create!(
          asset: asset,
          position: position,
          side: attrs[:side],
          shares: attrs[:shares],
          price_per_share: attrs[:price_per_share],
          fee: attrs[:fee] || 0,
          currency: currency,
          fx_rate_at_execution: fx_rate,
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
end
