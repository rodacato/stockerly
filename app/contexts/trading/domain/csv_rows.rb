require "csv"

module Trading
  module Domain
    # Raw CSV text -> the row hashes ImportTrades validates. Shared by the rake
    # task and the controller so the accepted shape is stated once.
    #
    # Unknown columns are dropped rather than rejected: a broker export carries
    # its own provenance (cusip, settle date, the source file) and none of it is
    # the importer's business.
    class CsvRows < SimpleUseCase
      KEYS = %i[asset_symbol side shares price_per_share fee currency executed_at external_id net_amount].freeze

      MissingHeader = Class.new(StandardError)
      REQUIRED = %i[asset_symbol side shares price_per_share executed_at].freeze

      def call(text:)
        table = CSV.parse(text.to_s, headers: true)
        raise MissingHeader, missing_message(table.headers) unless required_present?(table.headers)

        table.map { |row| row.to_h.symbolize_keys.slice(*KEYS) }
      rescue CSV::MalformedCSVError => e
        raise MissingHeader, e.message
      end

      private

      def required_present?(headers)
        REQUIRED.all? { |key| headers.include?(key.to_s) }
      end

      def missing_message(headers)
        missing = REQUIRED.reject { |key| headers.to_a.include?(key.to_s) }
        "Faltan columnas: #{missing.join(', ')}"
      end
    end
  end
end
