module TradingviewHelper
  EXCHANGE_MAP = {
    "stock" => "NASDAQ",
    "etf" => "AMEX",
    "crypto" => "COINBASE"
  }.freeze

  # Converts asset to TradingView "EXCHANGE:SYMBOL" format.
  # e.g. AAPL → "NASDAQ:AAPL", BTC → "COINBASE:BTCUSD"
  def tradingview_symbol(asset)
    exchange = EXCHANGE_MAP[asset.asset_type] || "NASDAQ"
    symbol = asset.symbol

    # Crypto symbols need USD suffix for TradingView
    symbol = "#{symbol}USD" if asset.asset_type_crypto?

    "#{exchange}:#{symbol}"
  end
end
