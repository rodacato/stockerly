module Assistant
  module Capabilities
    # Third-party text: quoted as published, never re-toned (ADR-031, prompt rule 5).
    class AssetNews < Capability
      declare "asset.news", required: %i[symbol],
                            description: "Recent headlines about an asset, quoted as published with their source and date."

      def cards(symbol:)
        data = brief(symbol)
        return [] if data.nil? || data[:headlines].blank?

        titles = data[:headlines].map { |item| "«#{item[:title]}» (#{item[:source]}, #{long_date(item[:published_at])})" }
        [ card(kind: "headlines", title: I18n.t("assistant.cards.titulares", symbol: data[:symbol]), body: titles.join(" ")) ]
      end
    end
  end
end
