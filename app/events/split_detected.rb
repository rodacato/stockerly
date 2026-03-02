class SplitDetected < BaseEvent
  attribute :asset_id, Types::Integer
  attribute :stock_split_id, Types::Integer
  attribute :ratio_from, Types::Integer
  attribute :ratio_to, Types::Integer
end
