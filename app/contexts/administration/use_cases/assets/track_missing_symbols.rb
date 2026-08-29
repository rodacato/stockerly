module Administration
  module UseCases
    module Assets
      # Adds catalogue entries for the bare tickers a CSV named, without
      # inventing any of them. The bundled catalogue answers what it knows for
      # free; everything else is left to the provider, off the request.
      class TrackMissingSymbols < ApplicationUseCase
        def call(symbols:, user:)
          wanted = normalize(symbols)
          return Failure([ :validation, "No symbols selected" ]) if wanted.empty?

          wanted -= Asset.where(symbol: wanted).pluck(:symbol)
          created = create_from_catalogue(wanted, user)
          pending = wanted - created

          ResolveTrackedSymbolsJob.perform_later(pending, user.id) if pending.any?

          Success({ created: created, pending: pending })
        end

        private

        def normalize(symbols)
          Array(symbols).map { |symbol| symbol.to_s.strip.upcase }.reject(&:blank?).uniq
        end

        # These cost no provider call and cannot be wrong: the catalogue carries
        # the type, venue, sector, country and currency a bare ticker does not.
        # An entry the contract refuses -- fixed income, which the importer has
        # already rejected upstream -- falls through to the provider and is
        # reported unresolved rather than swallowed.
        def create_from_catalogue(symbols, user)
          Administration::Domain::AssetCatalog.find_by_symbols(symbols).filter_map do |entry|
            result = CreateAsset.call(admin: user, params: entry.slice(:symbol, :name, :asset_type, :exchange, :sector, :country, :currency))
            result.success? ? entry[:symbol] : nil
          end
        end
      end
    end
  end
end
