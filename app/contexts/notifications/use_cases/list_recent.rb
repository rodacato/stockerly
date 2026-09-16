module Notifications
  module UseCases
    # Inbox query for /notifications. Returns the filtered relation, counts
    # used by the filter chip badges (always reflect the full unfiltered
    # dataset), and a shown/total pair for the "Mostrando X de Y" indicator.
    class ListRecent < SimpleUseCase
      DEFAULT_LIMIT = 100

      def call(user:, tipo: "todos", estado: "todos", limit: DEFAULT_LIMIT)
        scope    = user.notifications
        filtered = scope.by_tipo(tipo).by_estado(estado).recent.limit(limit).to_a

        {
          notifications: filtered,
          tipo:          tipo,
          estado:        estado,
          shown_count:   filtered.size,
          counts:        counts_for(scope)
        }
      end

      private

      def counts_for(scope)
        by_type = scope.group(:notification_type).count
        all     = by_type.values.sum
        unread  = scope.unread.count

        Notification::TIPO_SCOPES
          .transform_values { |types| types.sum { |t| by_type[t] || 0 } }
          .symbolize_keys
          .merge(all: all, unread: unread, read: all - unread)
      end
    end
  end
end
