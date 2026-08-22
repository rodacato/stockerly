module MarketData
  module Domain
    # Static reference data about each market-data provider: what it is used for
    # (es-MX, shown to the self-hoster) and where to get an API key. Keyed by
    # Integration#provider_name. `signup_url: nil` means the provider is public
    # (no key needed).
    module ProviderDirectory
      Info = Data.define(:description, :signup_url)

      ENTRIES = {
        "Polygon.io"     => Info.new("Precios e histórico de acciones de EE. UU.", "https://polygon.io/dashboard/signup"),
        "CoinGecko"      => Info.new("Precios de criptomonedas. La capa gratuita funciona sin key.", nil),
        "Yahoo Finance"  => Info.new("Precios de acciones y ETFs de la BMV (México).", nil),
        "Alternative.me" => Info.new("Índice de miedo y codicia de cripto (sentimiento).", nil),
        "CNN"            => Info.new("Índice de miedo y codicia del mercado de acciones (sentimiento).", nil),
        "Alpha Vantage"  => Info.new("Fundamentales de empresas (EPS, razones financieras).", "https://www.alphavantage.co/support/#api-key"),
        "FMP"            => Info.new("Dividendos y splits de tus posiciones.", "https://site.financialmodelingprep.com/developer/docs"),
        "ExchangeRate"   => Info.new("Tipos de cambio (FX) para consolidar en tu moneda base.", "https://www.exchangerate-api.com/"),
        "Banxico"        => Info.new("CETES y renta fija mexicana (tasas, subastas).", "https://www.banxico.org.mx/SieAPIRest/service/v1/token")
      }.freeze

      def self.for(provider_name)
        ENTRIES[provider_name]
      end
    end
  end
end
