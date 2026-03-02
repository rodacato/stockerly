module Administration
  class CsvExported < BaseEvent
    attribute :user_id, Types::Integer
    attribute :export_type, Types::String
  end
end
