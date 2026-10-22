module Assistant
  module Capabilities
    # One read the assistant may make. A subclass names itself, declares its
    # input and its budget, and turns a supplier's plain data into cards.
    class Capability
      MAX_CHARS = 600

      class << self
        attr_reader :name_in_registry, :description, :required, :optional

        def declare(name, description:, required: [], optional: [])
          @name_in_registry = name
          @description = description
          @required = required
          @optional = optional
        end

        def accepts?(input) = (required - input.keys).empty? && (input.keys - required - optional).empty?
      end

      def initialize(registry) = @registry = registry

      private

      def brief(symbol) = @registry.brief(symbol)

      def card(**fields) = Domain::Card.new(source: nil, figure: nil, body: nil, **fields)

      def money(value) = ActiveSupport::NumberHelper.number_to_delimited(format("%.2f", value))

      def long_date(time) = I18n.l(time.to_date, format: :long)
    end
  end
end
