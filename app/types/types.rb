module Types
  include Dry.Types()

  UserRole         = Types::String.enum("user", "admin")
  UserStatus       = Types::String.enum("active", "suspended")
  AssetType        = Types::String.enum("stock", "crypto", "index")
  SyncStatus       = Types::String.enum("active", "disabled", "sync_issue")
  TradeSide        = Types::String.enum("buy", "sell")
  AlertCondition   = Types::String.enum(
    "price_crosses_above", "price_crosses_below",
    "day_change_percent", "rsi_overbought", "rsi_oversold"
  )
  AlertStatus      = Types::String.enum("active", "paused")
  EventStatus      = Types::String.enum("triggered", "settled")
  PositionStatus   = Types::String.enum("open", "closed")
  EarningsTiming   = Types::String.enum("before_market_open", "after_market_close")
  LogSeverity      = Types::String.enum("success", "error", "warning")
  ConnectionStatus = Types::String.enum("connected", "syncing", "disconnected")
  NotificationType = Types::String.enum("alert_triggered", "earnings_reminder", "system")
  Currency         = Types::String.default("USD")
end
