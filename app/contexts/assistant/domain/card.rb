module Assistant
  module Domain
    # One piece of retrieved data, shown to the reader before the model writes
    # and handed to the model as its only source. `line` is what the model sees.
    Card = Data.define(:kind, :title, :body, :figure, :source) do
      def self.from_h(hash) = new(**hash.symbolize_keys.slice(*members))

      # Angle brackets go so third-party text (a headline) cannot close <datos>.
      def line = [ title, body, figure, source ].compact_blank.join(" · ").delete("<>")

      def within(max_chars) = body.to_s.length > max_chars ? with(body: body.truncate(max_chars, separator: " ")) : self
    end
  end
end
