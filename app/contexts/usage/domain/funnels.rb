module Usage
  module Domain
    # An offer and the action it leads to (ADR-032 §4, §6). The week is the
    # window: an action counts against the offers of the week it happened in.
    module Funnels
      Funnel = Data.define(:key, :offer, :action, :via)

      ALL = [
        Funnel.new(key: "rule_suggestion", offer: "rule_suggestion.shown", action: "rule.created", via: "rule_suggestion"),
        Funnel.new(key: "assistant_suggestion", offer: "assistant.suggestion_shown", action: "question.sent", via: "suggestion"),
        Funnel.new(key: "help_to_question", offer: "help.ask_velita", action: "question.sent", via: "help")
      ].freeze
    end
  end
end
