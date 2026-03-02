module Market
  class LoadAssetDetail < ApplicationUseCase
    def call(symbol:)
      asset = Asset.find_by(symbol: symbol.upcase)
      return Failure([ :not_found, "Asset not found" ]) unless asset

      if asset.asset_type_fixed_income?
        return Success({
          asset: asset,
          presenter: nil,
          has_fundamentals: false,
          yield_data: build_yield_data(asset)
        })
      end

      fundamental = resolve_fundamental(asset)
      presenter = FundamentalPresenter.new(asset: asset, fundamental: fundamental)

      price_histories = asset.asset_price_histories.where("date >= ?", 30.days.ago.to_date).order(:date)

      pe_history = if asset.asset_type_stock?
                     eps = fundamental&.metrics&.dig("eps")&.to_d
                     pe_histories = asset.asset_price_histories.where("date >= ?", 90.days.ago.to_date).order(:date)
                     PeHistoryCalculator.calculate(price_histories: pe_histories, eps: eps)
      end

      earnings_events = asset.asset_type_stock? ? asset.earnings_events.order(report_date: :desc).limit(8) : []
      dividends = asset.asset_type_stock? || asset.asset_type_etf? ? asset.dividends.order(ex_date: :desc).limit(12) : []

      Success({
        asset: asset,
        presenter: presenter,
        has_fundamentals: fundamental.present?,
        price_histories: price_histories,
        pe_history: pe_history,
        earnings_events: earnings_events,
        dividends: dividends
      })
    end

    private

    def build_yield_data(asset)
      days_to_maturity = asset.maturity_date ? (asset.maturity_date - Date.current).to_i : 0
      discount_price = asset.yield_rate ? YieldCalculator.discount_price(
        face_value: asset.face_value || 10.0,
        annual_yield: asset.yield_rate,
        days: [ days_to_maturity, 0 ].max
      ) : nil

      quantity_example = 100
      total_return = discount_price ? YieldCalculator.total_return(
        face_value: asset.face_value || 10.0,
        purchase_price: discount_price,
        quantity: quantity_example
      ) : nil

      {
        days_to_maturity: [ days_to_maturity, 0 ].max,
        discount_price: discount_price,
        total_return_100: total_return,
        investment_cost_100: discount_price ? (discount_price * quantity_example).round(2) : nil,
        face_value_100: YieldCalculator.investment_value(face_value: asset.face_value || 10.0, quantity: quantity_example)
      }
    end

    def resolve_fundamental(asset)
      if asset.asset_type_crypto?
        asset.asset_fundamentals.where(period_label: "CRYPTO_MARKET").latest.first
      else
        calculated = asset.asset_fundamentals.where(period_label: "CALCULATED").latest.first
        calculated || asset.asset_fundamentals.overview.latest.first
      end
    end
  end
end
