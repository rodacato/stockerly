module Usage
  module Domain
    # The closed list (ADR-032 §2). Each event names the metric it answers here
    # and, for the owner, a question under admin.usage.show.preguntas;
    # a property is kept only if declared, and only as a number or one of the
    # declared values, so no free text can be recorded.
    module Catalogue
      KEY = /\A[a-z0-9_]{1,40}\z/

      Event = Data.define(:name, :properties, :answers, :client) do
        def permit(given)
          properties.each_with_object({}) do |(key, allowed), kept|
            value = given[key]
            kept[key.to_s] = value.to_i if allowed == :integer && value.to_s.match?(/\A\d{1,6}\z/)
            kept[key.to_s] = value.to_s if allowed == :key && value.to_s.match?(KEY)
            kept[key.to_s] = value.to_s if allowed.is_a?(Array) && allowed.include?(value.to_s)
          end
        end
      end

      def self.event(name, answers:, properties: {}, client: false) = Event.new(name:, properties:, answers:, client:)

      EVENTS = [
        event("rule_suggestion.shown", properties: { condition: :key }, answers: "Suggestions on a cadence"),
        event("rule.created", properties: { via: %w[rule_suggestion direct] }, answers: "Suggestions on a cadence"),
        event("assistant.suggestion_shown", answers: "D166"),
        event("question.sent", properties: { via: %w[suggestion typed help retry] }, answers: "D166 · JTBD #8 · #890"),
        event("help.ask_velita", properties: { figure: :key }, answers: "JTBD #8"),
        event("asset.opened", properties: { from: %w[senales hoy radar activos search discover direct] }, answers: "JTBD #4 · JTBD #6 · D74"),
        event("news.opened", answers: "JTBD #7", client: true),
        event("trade.created", properties: { seconds: :integer }, answers: "JTBD #5"),
        event("velita.colour_changed", properties: { colour: :key }, answers: "#899")
      ].index_by(&:name).freeze

      def self.find(name) = EVENTS[name.to_s]

      def self.client?(name) = find(name)&.client == true
    end
  end
end
