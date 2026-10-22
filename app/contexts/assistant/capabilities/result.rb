module Assistant
  module Capabilities
    # A capability answers with cards or says why it could not; an empty
    # success would read to the composer as "there is nothing", which is a claim.
    Result = Data.define(:name, :cards, :reason) do
      def self.ok(name, cards) = new(name: name, cards: cards, reason: nil)
      def self.failed(name, reason) = new(name: name, cards: [], reason: reason)

      def ok? = reason.nil?
    end
  end
end
