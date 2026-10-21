module Administration
  module UseCases
    module Assets
      # Idempotent: a mapped asset is never asked about again, and an unconfirmed name is reported, never guessed.
      class ResolveBmvSymbols < SimpleUseCase
        Resolution = Data.define(:resolved, :unresolved)

        PROVIDER = MarketData::Gateways::DataBursatilGateway::PROVIDER

        def call(&report)
          pending = pending_assets
          return Resolution.new([], []) if pending.empty?

          gateway = MarketData::Gateways::DataBursatilGateway.new
          resolved = []
          unresolved = []

          pending.each do |asset|
            answer = confirmed_name(gateway, asset)
            if answer
              asset.update!(provider_symbols: asset.provider_symbols.merge(PROVIDER => answer))
              resolved << [ asset.symbol, answer ]
            else
              unresolved << asset.symbol
            end
            report&.call(asset, answer)
          end

          Resolution.new(resolved, unresolved)
        end

        def pending_assets
          Asset.where(country: "MX")
               .select { |asset| served?(asset) }
               .reject { |asset| asset.provider_symbols.key?(PROVIDER) }
        end

        private

        # CETES are priced by Banxico, so probing them spends requests to learn nothing.
        def served?(asset)
          DataSourceRegistry
            .for_capability(:prices, market: asset.market, asset_type: asset.asset_type)
            .any? { |source| source.integration_name == PROVIDER }
        end

        # Yahoo omits the serie when it is `*`: the bare name first, the starred one second.
        def confirmed_name(gateway, asset)
          base = asset.symbol.to_s.upcase.delete_suffix(".MX")
          [ base, "#{base}*" ].find { |candidate| gateway.fetch_price(candidate).success? }
        end
      end
    end
  end
end
