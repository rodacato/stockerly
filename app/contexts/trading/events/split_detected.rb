module Trading
  module Events
    class SplitDetected < BaseEvent
      attribute :asset_id, Types::Integer
      attribute :ex_date, Types::Date
      attribute :ratio_from, Types::Integer
      attribute :ratio_to, Types::Integer
    end
  end
end
