module MarketData
  module Domain
    # Static reference data per market-data provider: what it is used for (es-MX,
    # shown to the self-hoster), a link to its site/source, and whether it needs
    # an API key. Keyed by Integration#provider_name.
    module ProviderDirectory
      Info = Data.define(:description, :url, :requires_key)

      ENTRIES = {
        # Need an API key (or token)
        "DataBursatil"   => Info.new("Precios, histórico e intradía de la BMV y BIVA. La cuota se mide en KiB transmitidos, no en llamadas.", "https://databursatil.com", true),
        "Alpaca"         => Info.new("Cierres confirmados e histórico de acciones de EE. UU., más dividendos y titulares. La llave se guarda como ID:SECRETO.", "https://app.alpaca.markets/signup", true),
        "Finnhub"        => Info.new("Cotización actual de acciones de EE. UU., reportes trimestrales y búsqueda.", "https://finnhub.io/register", true),
        "Polygon.io"     => Info.new("Precios e histórico de acciones de EE. UU.", "https://polygon.io/dashboard/signup", true),
        "Alpha Vantage"  => Info.new("Fundamentales de empresas (EPS, razones financieras).", "https://www.alphavantage.co/support/#api-key", true),
        "FMP"            => Info.new("Dividendos y splits de tus posiciones.", "https://site.financialmodelingprep.com/developer/docs", true),
        "ExchangeRate"   => Info.new("Tipos de cambio (FX) para consolidar en tu moneda base.", "https://www.exchangerate-api.com/", true),
        "Banxico"        => Info.new("CETES y renta fija mexicana (tasas, subastas).", "https://www.banxico.org.mx/SieAPIRest/service/v1/token", true),
        "CoinGecko"      => Info.new("Precios de criptomonedas. La Demo API key (gratis) sube los límites.", "https://www.coingecko.com/en/api/pricing", true),

        # Public — no key needed
        "Yahoo Finance"  => Info.new("Precios de acciones y ETFs de la BMV (México).", "https://finance.yahoo.com", false),
        "Alternative.me" => Info.new("Índice de miedo y codicia de cripto (sentimiento).", "https://alternative.me/crypto/fear-and-greed-index/", false)
      }.freeze

      def self.for(provider_name)
        ENTRIES[provider_name]
      end
    end
  end
end
