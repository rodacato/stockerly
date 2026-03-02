class BaseEvent < Dry::Struct
  attribute :occurred_at, Types::DateTime.default { DateTime.current }

  def event_name
    self.class.name.underscore.tr("/", ".")
  end
end
