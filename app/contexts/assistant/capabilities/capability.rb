module Assistant
  module Capabilities
    # One read the assistant may make. A subclass names itself, declares its
    # input and its budget, and turns a supplier's plain data into cards.
    class Capability
      MAX_CHARS = 600

      class << self
        attr_reader :name_in_registry, :description, :required, :optional

        # A holdings read exists only while the owner's switch is on (ADR-031's 2026-10-22 amendment).
        def declare(name, description:, required: [], optional: [], holdings: false)
          @name_in_registry = name
          @description = description
          @required = required
          @optional = optional
          @holdings = holdings
        end

        def holdings? = @holdings

        def accepts?(input) = (required - input.keys).empty? && (input.keys - required - optional).empty?
      end

      def initialize(registry) = @registry = registry

      private

      def brief(symbol) = @registry.brief(symbol)

      def card(**fields) = Domain::Card.new(source: nil, figure: nil, body: nil, **fields)

      def money(value) = ActiveSupport::NumberHelper.number_to_delimited(format("%.2f", value))

      def long_date(time) = I18n.l(time.to_date, format: :long)

      def helpers = ApplicationController.helpers

      # The page's own label for a provider ("Banxico", not its series id), so
      # the prose never repeats an internal code.
      def source_label(source) = helpers.source_label(source)&.upcase_first
    end
  end
end
