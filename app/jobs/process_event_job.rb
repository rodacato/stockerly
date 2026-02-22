class ProcessEventJob < ApplicationJob
  queue_as :default

  def perform(handler_class_name, event_data)
    handler = handler_class_name.constantize
    handler.call(event_data.symbolize_keys)
  end
end
