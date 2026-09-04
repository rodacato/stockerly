module Administration
  module UseCases
    module Assets
      # The catalogue's entry point for a context that needs a row to exist
      # before it can write the columns it owns (ADR-024). Identity and
      # lifecycle are written here, by their owner, and only on creation — a
      # data sync must not rename a listing or re-enable one the reader
      # disabled from /tracked.
      class EnsureListed < SimpleUseCase
        def call(symbol:, attributes: {})
          Asset.find_or_create_by!(symbol: symbol) do |asset|
            attributes.each { |column, value| asset.public_send(:"#{column}=", value) }
          end
        end
      end
    end
  end
end
