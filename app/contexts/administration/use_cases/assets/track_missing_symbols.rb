module Administration
  module UseCases
    module Assets
      # Adds catalogue entries for the bare tickers a CSV named, without
      # inventing any of them. The bundled catalogue answers what it knows for
      # free; everything else is left to the provider, off the request.
      class TrackMissingSymbols < ApplicationUseCase
        # `renames` maps a symbol in the file to the ticker it trades under
        # today; `delisted` lists the ones that trade nowhere. Both are the
        # owner's word, taken only for the symbols they typed it against.
        def call(symbols:, user:, renames: {}, delisted: [])
          wanted = normalize(symbols)
          return Failure([ :validation, "No symbols selected" ]) if wanted.empty?

          wanted -= Asset.where(symbol: wanted).pluck(:symbol)
          renamed = adopt_renames(wanted, renames, user)
          frozen  = freeze_delisted(wanted, delisted, user)

          rest    = wanted - renamed - frozen
          created = create_from_catalogue(rest, user)
          pending = rest - created

          ResolveTrackedSymbolsJob.perform_later(pending, user.id) if pending.any?

          Success({ created: created + renamed + frozen, pending: pending })
        end

        private

        # The live ticker is what gets looked up and created, because that is
        # what syncs; the old one is recorded beside it. An asset that already
        # exists just learns the former name.
        def adopt_renames(wanted, renames, user)
          normalize(renames.keys).filter_map do |former|
            current = renames[former].to_s.strip.upcase.presence
            next if current.blank? || !wanted.include?(former)

            asset = Asset.find_by(symbol: current) || create_from_provider(current, user)
            next if asset.nil?

            asset.update!(former_symbols: (asset.former_symbols + [ former ]).uniq)
            former
          end
        end

        # Nothing to resolve and nothing to ask: it exists so the trades keep
        # their cost, and `disabled` is what every sync job already filters out.
        def freeze_delisted(wanted, delisted, user)
          normalize(delisted).select { |symbol| wanted.include?(symbol) }.filter_map do |symbol|
            result = CreateAsset.call(admin: user, params: { symbol: symbol, name: symbol, asset_type: "stock" })
            next unless result.success?

            result.value!.update!(sync_status: :disabled)
            symbol
          end
        end

        def create_from_provider(symbol, user)
          result = SearchTicker.call(query: symbol)
          return nil if result.failure?

          match = result.value!.find { |candidate| candidate[:symbol].to_s.upcase == symbol }
          return nil if match.nil?

          created = CreateAsset.call(admin: user, params: match.slice(:symbol, :name, :asset_type, :exchange, :sector, :country, :currency).compact)
          created.success? ? created.value! : nil
        end

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
