class EventBus
  @handlers = Hash.new { |h, k| h[k] = [] }

  class << self
    def subscribe(event_class, handler)
      @handlers[event_class.name] << handler
    end

    def publish(event)
      @handlers[event.class.name].each do |handler|
        if handler.respond_to?(:async?) && handler.async?
          ProcessEventJob.perform_later(handler.name, serialize(event))
        else
          handler.call(event)
        end
      end
    end

    def clear!
      @handlers = Hash.new { |h, k| h[k] = [] }
    end

    def handlers_for(event_class)
      @handlers[event_class.name].dup
    end

    private

    def serialize(event)
      event.to_h.transform_values do |v|
        v.is_a?(DateTime) || v.is_a?(Time) ? v.iso8601 : v
      end
    end
  end
end
