module Administration
  module Events
    class CsvExported < BaseEvent
      attribute :user_id, Types::Integer
      attribute :export_type, Types::String
    end
  end
end
