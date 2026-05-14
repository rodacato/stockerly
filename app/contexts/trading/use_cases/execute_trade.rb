module Trading
  module UseCases
    class ExecuteTrade < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Trading::Contracts::ExecuteTradeContract, params)
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        asset = Asset.find_by!(symbol: attrs[:asset_symbol].upcase)
        position = find_or_create_position(portfolio, asset, attrs)

        return Failure([ :insufficient_shares, "Not enough shares to sell" ]) if sell_exceeds_position?(attrs, position)

        trade_currency = attrs[:currency] || asset.currency
        fx_rate = yield resolve_fx_rate(trade_currency, user.preferred_currency, attrs[:fx_rate_at_execution])

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

      def find_or_create_position(portfolio, asset, attrs)
        existing = portfolio.positions.find_by(asset: asset, status: :open)
        return existing if existing
        return nil if attrs[:side] == "sell"

        portfolio.positions.create!(
          asset: asset,
          shares: 0,
          avg_cost: attrs[:price_per_share],
          opened_at: Time.current,
          status: :open
        )
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

      # Returns the FX rate expressing 1 unit of `trade_currency` in `preferred_currency`.
      # Resolution order:
      #   1. Same currency → 1.0
      #   2. Explicit override from params (manual entry)
      #   3. Latest FxRate row in DB (forward)
      #   4. Best-effort gateway refresh, retry forward
      #   5. Inverse FxRate row (1 / reverse-direction rate)
      #   6. Failure(:fx_rate_unavailable)
      #
      # Note: we capture FX *at record time*, not at trade execution time (S2 pragmatic
      # call — no historical FX storage yet). For backdated trades needing precision,
      # pass `fx_rate_at_execution` explicitly in params. See PR #42 notes.
      # Cross-context call to MarketData is a known leak tracked for Sprint 5.
      def resolve_fx_rate(trade_currency, preferred_currency, override)
        return Success(BigDecimal(1)) if trade_currency == preferred_currency
        return Success(override) if override

        rate = FxRate.convert(1, from: trade_currency, to: preferred_currency)
        return Success(rate) if rate

        refresh_fx_rates(base: trade_currency, target: preferred_currency)
        rate = FxRate.convert(1, from: trade_currency, to: preferred_currency)
        return Success(rate) if rate

        inverse = FxRate.convert(1, from: preferred_currency, to: trade_currency)
        return Success(BigDecimal(1) / inverse) if inverse && inverse > 0

        Failure([ :fx_rate_unavailable, "Could not determine FX rate: #{trade_currency} -> #{preferred_currency}" ])
      end

      def refresh_fx_rates(base:, target:)
        MarketData::Gateways::FxRatesGateway.new.refresh_rates(base: base, targets: [ target ])
      rescue StandardError
        nil
      end
    end
  end
end
