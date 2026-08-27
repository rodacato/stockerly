module Administration
  module UseCases
    module Assets
      # Records what one provider calls an instrument — the BMV wants `WALMEX*`
      # where Yahoo says `WALMEX.MX`. The name is stored only once the provider
      # has answered to it: a wrong mapping is worse than none, because the sync
      # then fails on a name the owner believes is right.
      class MapProviderSymbol < ApplicationUseCase
        def call(asset_id:, provider:, symbol:)
          asset = Asset.find(asset_id)
          candidate = symbol.to_s.strip.upcase

          return Failure([ :validation, :vacio ]) if candidate.blank?

          source = source_for(asset, provider)
          return Failure([ :not_found, :no_sirve ]) if source.nil?
          return Failure([ :unconfirmed, candidate ]) unless answers?(source, candidate)

          asset.update!(
            provider_symbols: asset.provider_symbols.merge(provider => candidate),
            last_sync_error: nil
          )

          Success(asset)
        end

        private

        # The registry already knows which sources serve this asset's market and
        # type, so the screen cannot map it to one that was never in its chain.
        def source_for(asset, provider)
          DataSourceRegistry
            .for_capability(:prices, market: asset.market, asset_type: asset.asset_type)
            .find { |source| source.integration_name == provider }
        end

        def answers?(source, candidate)
          source.gateway_class.new.fetch_price(candidate).success?
        rescue MarketData::Gateways::ApiKeyNotConfiguredError
          false
        end
      end
    end
  end
end
