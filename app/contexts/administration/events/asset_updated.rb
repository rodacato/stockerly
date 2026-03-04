module Administration
  module Events
    class AssetUpdated < BaseEvent
      attribute :asset_id, Types::Integer
      attribute :symbol, Types::String
      attribute :changes, Types::Hash
    end
  end
end
