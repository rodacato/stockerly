module Identity
  module UseCases
    # ADR-006: pure read, no failure path → SimpleUseCase.
    class LoadAssetCatalog < SimpleUseCase
      def call(types: [ :stock, :crypto, :etf ], limit: 20)
        Asset.where(asset_type: types).order(:name).limit(limit)
      end
    end
  end
end
