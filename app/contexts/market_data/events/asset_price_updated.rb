module MarketData
  module Events
    class AssetPriceUpdated < BaseEvent
      attribute :asset_id, Types::Integer
      attribute :symbol, Types::String
      attribute :old_price, Types::String
      attribute :new_price, Types::String
      attribute :volume, Types::String.optional.meta(omittable: true)
      # Which provider produced this price. Optional so a publisher that does
      # not know cannot be forced to invent one.
      attribute :source, Types::String.optional.meta(omittable: true)
    end
  end
end
