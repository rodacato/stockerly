module Cetes
  class SyncAuctions < ApplicationUseCase
    TERMS = %w[28 91 182 364].freeze

    def call
      synced = 0

      TERMS.each do |term|
        result = BanxicoGateway.new.fetch_auctions(term: term)
        next if result.failure?

        result.value!.each do |data|
          upsert_cetes_asset(term, data)
          synced += 1
        end
      end

      publish(CetesSynced.new(count: synced))

      Success(synced)
    end

    private

    def upsert_cetes_asset(term, data)
      asset = Asset.find_or_initialize_by(symbol: "CETES_#{term}D")
      days = term.to_i
      discount_price = YieldCalculator.discount_price(
        face_value: 10.0,
        annual_yield: data[:yield_rate],
        days: days
      )

      asset.update!(
        name: "CETES #{term} Days",
        asset_type: :fixed_income,
        yield_rate: data[:yield_rate],
        face_value: 10.0,
        maturity_date: Date.current + days.days,
        exchange: "Banxico",
        country: "MX",
        current_price: discount_price,
        price_updated_at: Time.current,
        sync_status: :active
      )
    rescue ActiveRecord::RecordInvalid
      nil
    end
  end
end
