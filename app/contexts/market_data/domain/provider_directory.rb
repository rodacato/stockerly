module MarketData
  module Domain
    # Static reference data per market-data provider: what it is used for (es-MX,
    # shown to the self-hoster), a link to its site/source, and whether it needs
    # an API key. Keyed by Integration#provider_name.
    module ProviderDirectory
      # `without` is what the owner loses by not configuring the key. A screen
      # that lists sources without saying that asks for a decision it has not
      # given the reader the facts to make.
      Info = Data.define(:description, :url, :requires_key, :without)

      ENTRIES = {
        # Need an API key (or token)
        "DataBursatil"   => Info.new("Precios, histórico e intradía de la BMV y BIVA. La cuota se mide en KiB transmitidos, no en llamadas.", "https://databursatil.com", true,
                                     "Tus acciones mexicanas dejan de actualizarse. El respaldo es Yahoo, que va más lento y no trae intradía."),
        "Alpaca"         => Info.new("Cierre confirmado e histórico de acciones de EE. UU., más sus dividendos y splits. La llave se guarda como ID:SECRETO.", "https://app.alpaca.markets/signup", true,
                                     "Pierdes el cierre oficial de EE. UU. y los dividendos y splits de tus posiciones estadounidenses."),
        "Finnhub"        => Info.new("Cotización del momento de acciones de EE. UU., reportes trimestrales y búsqueda de tickers.", "https://finnhub.io/register", true,
                                     "El precio de tus acciones de EE. UU. queda en el cierre del día anterior, y la búsqueda de tickers deja de funcionar."),
        "Alpha Vantage"  => Info.new("Fundamentales de empresas (EPS, razones financieras). 25 llamadas al día en el plan gratuito.", "https://www.alphavantage.co/support/#api-key", true,
                                     "Las pestañas de fundamentales y estados financieros se quedan vacías."),
        "FMP"            => Info.new("Respaldo de fundamentales cuando Alpha Vantage se queda sin sus 25 llamadas del día. Solo sirve con llaves de cuentas creadas antes del 31 de agosto de 2025.", "https://site.financialmodelingprep.com/developer/docs", true,
                                     "Nada, salvo que los fundamentales se detengan al agotar la cuota de Alpha Vantage en vez de continuar."),
        "ExchangeRate"   => Info.new("Tipo de cambio del momento, para ver todo en tu moneda base. El histórico por fecha lo trae Banxico.", "https://www.exchangerate-api.com/", true,
                                     "Tu patrimonio se consolida con el último tipo de cambio que se haya guardado, sin actualizarse — y sin decírtelo."),
        "Banxico"        => Info.new("Tipo de cambio FIX (el que liquida un broker mexicano) y CETES.", "https://www.banxico.org.mx/SieAPIRest/service/v1/token", true,
                                     "Un movimiento con fecha pasada se valúa al tipo de cambio de hoy, no al del día en que ocurrió."),
        "CoinGecko"      => Info.new("Precios de criptomonedas. La Demo API key (gratis) sube los límites.", "https://www.coingecko.com/en/api/pricing", true,
                                     "Tus criptos dejan de actualizarse por completo: no hay otra fuente."),

        # Public — no key needed
        "Yahoo Finance"  => Info.new("Índices (IPC, S&P, Dow) y corporativos de la BMV. Además es el último respaldo de casi todo lo demás.", "https://finance.yahoo.com", false,
                                     "Los índices y los dividendos mexicanos se detienen, y el resto se queda sin su última red."),
        "Alternative.me" => Info.new("Índice de miedo y codicia de cripto (sentimiento).", "https://alternative.me/crypto/fear-and-greed-index/", false,
                                     "Desaparece la tarjeta de sentimiento de cripto.")
      }.freeze

      def self.for(provider_name)
        ENTRIES[provider_name]
      end
    end
  end
end
