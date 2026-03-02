module MarketData
  class FinancialStatementsSynced < BaseEvent
    attribute :asset_id, Types::Integer
    attribute :symbol, Types::String
    attribute :statement_types, Types::Array.of(Types::String)
  end
end
