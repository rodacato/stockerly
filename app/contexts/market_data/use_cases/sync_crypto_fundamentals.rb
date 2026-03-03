module MarketData
  module UseCases
    class SyncCryptoFundamentals < ApplicationUseCase
      def call(asset:)
        return Failure([ :invalid, "Not a crypto asset" ]) unless asset.asset_type_crypto?

        result = Gateways::CoingeckoGateway.new.fetch_market_data([ asset.symbol ])
        data = yield result
        entry = data.first
        return Failure([ :not_found, "No market data for #{asset.symbol}" ]) unless entry

        metrics = build_metrics(entry)

        fundamental = asset.asset_fundamentals.find_or_initialize_by(period_label: "CRYPTO_MARKET")
        fundamental.update!(metrics: metrics, calculated_at: Time.current)

        Success(fundamental)
      end

      private

      def build_metrics(entry)
        {
          "market_cap" => entry[:market_cap]&.to_s,
          "circulating_supply" => entry[:circulating_supply]&.to_s,
          "total_supply" => entry[:total_supply]&.to_s,
          "max_supply" => entry[:max_supply]&.to_s,
          "fully_diluted_valuation" => entry[:fully_diluted_valuation]&.to_s,
          "total_volume_24h" => entry[:total_volume]&.to_s,
          "ath_price" => entry[:ath]&.to_s,
          "ath_change_percentage" => entry[:ath_change_percentage]&.to_s,
          "atl_price" => entry[:atl]&.to_s,
          "atl_change_percentage" => entry[:atl_change_percentage]&.to_s,
          "volume_market_cap_ratio" => compute_vol_mcap_ratio(entry)
        }
      end

      def compute_vol_mcap_ratio(entry)
        return nil unless entry[:total_volume] && entry[:market_cap]&.nonzero?

        ((entry[:total_volume].to_f / entry[:market_cap].to_f) * 100).round(2).to_s
      end
    end
  end
end
