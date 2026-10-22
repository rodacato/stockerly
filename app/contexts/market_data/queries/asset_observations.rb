module MarketData
  module Queries
    # ADR-031: the asset page's recent observations as plain data, read with
    # the page's own window and phrase table so the two cannot disagree.
    class AssetObservations
      # @api public
      def self.call(symbol:, limit: 5)
        asset = AssetLookup.by_symbol(symbol)
        return nil unless asset

        observations = asset.technical_observations.recent
                            .within_last(UseCases::LoadAssetDetail::OBSERVATION_WINDOW_DAYS)
                            .limit(limit)

        { symbol: asset.symbol, observations: observations.map { |row| observation(row) }.freeze }.freeze
      end

      # ADR-013: the verb is a lookup over the persisted type, never composed here.
      def self.observation(row)
        type = row.observation_type
        verb = Domain::ObservationAction.for(type)

        {
          type: type,
          observed_at: row.observed_at,
          reading: Domain::ObservationPhrases.for(type),
          action: verb && I18n.t("comun.accion.#{verb}")
        }.freeze
      end
      private_class_method :observation
    end
  end
end
