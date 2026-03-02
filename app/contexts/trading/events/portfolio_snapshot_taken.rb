module Trading
  class PortfolioSnapshotTaken < BaseEvent
    attribute :snapshot_id, Types::Integer
    attribute :portfolio_id, Types::Integer
    attribute :total_value, Types::String
  end
end
